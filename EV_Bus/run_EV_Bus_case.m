function [logout, report, out] = run_EV_Bus_case(measurementFile, options)
%RUN_EV_BUS_CASE Import, scale, tune and verify a forward bus measurement case.
% [logout,report,out] = run_EV_Bus_case(file,options)
% See GENERIC_COMPENSATOR.md for the MAT schema, options and limitations.
% Simulink equations use basic blocks; this function configures simulations.
if nargin<2, options=struct; end
allowed={'ReuseModelProfiles','Vehicle','SpeedProfile','SlopeProfile', ...
    'TemperatureProfile','InitialSpeed_mps','StationaryWindow','Bias_N', ...
    'NoiseSigma_N','ForceLimit_N','MinAdaptSpeed_mps','Apply','AutoTune', ...
    'MaxSpeedRMSE_kmph'};
assert(isstruct(options)&&isscalar(options),'Options must be a scalar struct.');
assert(all(ismember(fieldnames(options),allowed)),'Unknown option name.');
folder=fileparts(mfilename('fullpath'));
model='EV_Bus_Forward';
open_system(fullfile(folder,[model '.slx']));
mw=get_param(model,'ModelWorkspace');
d=load(measurementFile);
if isfield(d,'ForceUnits'), assert(strcmpi(string(d.ForceUnits),'N'),'Force must be in N.'); end
if isfield(d,'TimeUnits'), assert(strcmpi(string(d.TimeUnits),'s'),'Time must be in seconds.'); end
if isfield(d,'measurementTime')&&isfield(d,'measurementForce')
    originalTime=d.measurementTime(:); force=d.measurementForce(:);
elseif isfield(d,'meas_time')&&isfield(d,'meas_traction_froce')
    originalTime=d.meas_time(:); force=d.meas_traction_froce(:);
else
    error('EVBus:Schema','Supply measurementTime and measurementForce (s and N).');
end
assert(isnumeric(originalTime)&&isreal(originalTime)&&isnumeric(force)&&isreal(force));
assert(numel(force)==numel(originalTime)&&numel(force)>=50,'Need at least 50 paired samples.');
assert(all(isfinite([originalTime force]),'all'),'Missing/nonfinite samples: repair explicitly first.');
intervals=diff(originalTime);
assert(all(intervals>0),'Duplicate or non-increasing timestamps.');
dt=median(intervals);
assert(max(intervals)<3*dt,'Large measurement gaps: split the recording or repair explicitly.');
timeOffset=originalTime(1); t=originalTime-timeOffset; duration=t(end);
assert(duration>=10,'Need at least 10 s for split-interval assessment.');

P=getVariable(mw,'P');
if isfield(d,'P'), P=mergeKnown(P,d.P); end
if isfield(options,'Vehicle'), P=mergeKnown(P,options.Vehicle); end
fields=fieldnames(P);
for j=1:numel(fields)
    value=P.(fields{j});
    assert(isnumeric(value)&&isreal(value)&&isscalar(value)&&isfinite(value), ...
        'Vehicle parameter %s must be finite scalar.',fields{j});
    assert(value>=0,'Vehicle parameter %s must not be negative.',fields{j});
end
positive={'Mass','Gravity','MotorCount','MotorPower','MotorPeakTorque','RegenPeakTorque', ...
    'RegenPower','MaxRPM','GearRatio','GearEfficiency','WheelRadius','AirPressure', ...
    'AirGasConstant','MotorLag','BrakeLag','MaxBrakeTorque','MaxPressure','DriverKp', ...
    'RegenFadeSpeed','RollingFadeSpeed'};
for j=1:numel(positive), assert(P.(positive{j})>0,'%s must be positive.',positive{j}); end
assert(P.GearEfficiency<=1&&P.MotorCount==round(P.MotorCount));
reuse=opt(options,'ReuseModelProfiles',false);
profileNames={'SpeedProfile','SlopeProfile','TemperatureProfile'};
profiles=struct;
for j=1:numel(profileNames)
    name=profileNames{j};
    if isfield(options,name), a=options.(name);
    elseif isfield(d,name), a=d.(name);
    elseif reuse, a=getVariable(mw,name);
    else, error('EVBus:Profiles','Supply %s in the MAT file/options, or explicitly set ReuseModelProfiles=true.',name);
    end
    assert(isnumeric(a)&&isreal(a)&&size(a,2)==2&&size(a,1)>=2&&all(isfinite(a),'all'));
    assert(all(diff(a(:,1))>0),'%s times must increase.',name);
    assert(a(1,1)<=originalTime(1)&&a(end,1)>=originalTime(end),'%s does not cover measurement timestamps.',name);
    a(:,1)=a(:,1)-timeOffset; profiles.(name)=a;
end
desired=interp1(profiles.SpeedProfile(:,1),profiles.SpeedProfile(:,2),t);
grade=interp1(profiles.SlopeProfile(:,1),profiles.SlopeProfile(:,2),t);
assert(min(desired)>=0,'Reverse driving is outside this model.');
assert(min(profiles.TemperatureProfile(:,2))>-273.15,'Invalid air temperature.');
if isfield(options,'InitialSpeed_mps')
    P.InitialSpeed=options.InitialSpeed_mps;
elseif isfield(d,'measuredSpeed_kmph')
    assert(numel(d.measuredSpeed_kmph)==numel(t)&&all(isfinite(d.measuredSpeed_kmph(:)))&&all(d.measuredSpeed_kmph(:)>=0));
    P.InitialSpeed=d.measuredSpeed_kmph(1)/3.6;
elseif desired(1)<0.1
    P.InitialSpeed=0;
else
    error('EVBus:InitialSpeed','Recording starts in motion: supply InitialSpeed_mps or measuredSpeed_kmph.');
end
assert(isscalar(P.InitialSpeed)&&isfinite(P.InitialSpeed)&&P.InitialSpeed>=0);

assert(~(isfield(options,'Bias_N')&&isfield(options,'StationaryWindow')), ...
    'Choose explicit bias OR a stationary calibration window.');
bias=opt(options,'Bias_N',0); biasMethod='provided or zero; no automatic parked assumption';
noise=1.4826*median(abs(diff(force)-median(diff(force))))/sqrt(2);
if isfield(options,'StationaryWindow')
    window=options.StationaryWindow;
    assert(numel(window)==2&&all(isfinite(window))&&window(2)>window(1));
    assert(window(1)>=originalTime(1)&&window(2)<=originalTime(end));
    parked=originalTime>=window(1)&originalTime<=window(2);
    assert(nnz(parked)>=20&&max(desired(parked))<0.1&&max(abs(grade(parked)))<0.1, ...
        'Bias window must contain at least 20 zero-target, level-road samples.');
    if isfield(d,'measuredSpeed_kmph')
        assert(max(abs(d.measuredSpeed_kmph(parked)))<0.1,'Measured vehicle is moving in bias window.');
    end
    values=force(parked); center=median(values);
    spread=1.4826*median(abs(values-center));
    keep=abs(values-center)<=max(6*spread,eps(max(abs(values))+1));
    bias=mean(values(keep)); noise=max(spread,noise);
    biasMethod='user-designated stationary window; robust trimmed mean';
end
assert(isscalar(bias)&&isfinite(bias));
noise=opt(options,'NoiseSigma_N',noise);
assert(isscalar(noise)&&isfinite(noise)&&noise>=0);

% Dimensionally scaled defaults: wheel-force capability and driver response.
driveForce=P.MotorCount*P.MotorPeakTorque*P.GearRatio*P.GearEfficiency/P.WheelRadius;
movingReference=desired(desired>1)/3.6;
if isempty(movingReference), typicalSpeed=1; else, typicalSpeed=median(movingReference); end
availableForce=min(driveForce,P.MotorCount*P.MotorPower*P.GearEfficiency/max(typicalSpeed,1));
driverTime=P.Mass/(P.DriverKp*availableForce);
baseTau=max([0.5,driverTime,5*P.MotorLag,3*P.BrakeLag]);
Comp=struct('Tau',baseTau,'Limit',min(0.03*P.Mass*P.Gravity,0.25*driveForce), ...
    'InitialForce',0,'Enable',1,'MinAdaptSpeed',opt(options,'MinAdaptSpeed_mps',0.5), ...
    'MeasurementStart',0,'MeasurementEnd',duration);
Comp.Limit=opt(options,'ForceLimit_N',Comp.Limit);
assert(isscalar(Comp.Limit)&&isfinite(Comp.Limit)&&Comp.Limit>0);
assert(isscalar(Comp.MinAdaptSpeed)&&isfinite(Comp.MinAdaptSpeed)&&Comp.MinAdaptSpeed>0);
Comp.FilterTau=max(5*dt,0.2*baseTau);
Comp.Deadband=max(1e-6*P.Mass*P.Gravity,noise*sqrt(dt/(2*Comp.FilterTau+dt)));
Comp.ErrorClip=max(8*noise,0.6*Comp.Limit);
Comp.MaxRate=0.3*Comp.Limit/baseTau;
Comp.LogSampleTime=dt;
Comp.MaxStep=min([dt,Comp.FilterTau/5,P.MotorLag/5,P.BrakeLag/5]);
if Comp.Deadband>0.25*Comp.Limit
    error('EVBus:Noise','Estimated noise is too large relative to the allowed physical correction. Check units/data.');
end

in=Simulink.SimulationInput(model);
in=in.setModelParameter('ReturnWorkspaceOutputs','on','StopTime',num2str(duration,17));
in=in.setVariable('P',P,'Workspace',model);
in=in.setVariable('MeasuredTraction',[t force],'Workspace',model);
in=in.setVariable('MeasuredForceBias',bias,'Workspace',model);
in=in.setVariable('CaseStopTime',duration,'Workspace',model);
for j=1:numel(profileNames)
    name=profileNames{j}; in=in.setVariable(name,profiles.(name),'Workspace',model);
end
disabled=Comp; disabled.Enable=0;
baseline=sim(in.setVariable('Comp',disabled,'Workspace',model));
z0=baseline.logout.signals.values; st=baseline.logout.time;
assert(all(isfinite(z0),'all'));
moving=z0(:,15)>Comp.MinAdaptSpeed;
train=moving&st<=0.6*duration; validation=moving&st>0.6*duration;
speedTolerance=opt(options,'MaxSpeedRMSE_kmph',max(3,0.05*max(desired)));
assert(isscalar(speedTolerance)&&isfinite(speedTolerance)&&speedTolerance>0);
baselineSpeed=sqrt(mean((z0(:,1)-z0(:,16)).^2));
baselineMeasuredSpeed=NaN;
if isfield(d,'measuredSpeed_kmph')
    assert(numel(d.measuredSpeed_kmph)==numel(t)&&all(isfinite(d.measuredSpeed_kmph(:)))&&all(d.measuredSpeed_kmph(:)>=0));
    alignedMeasuredSpeed=interp1(t,d.measuredSpeed_kmph(:),st);
    baselineMeasuredSpeed=sqrt(mean((z0(:,16)-alignedMeasuredSpeed).^2));
end
report=struct('status','disabled_no_accepted_candidate','measurementFile',char(measurementFile), ...
    'timeOffset_s',timeOffset,'duration_s',duration,'sampleTime_s',dt, ...
    'noiseSigma_N',noise,'bias_N',bias,'biasMethod',biasMethod,'Vehicle',P, ...
    'baselineRMSE_N',sqrt(mean(z0(:,32).^2)),'baselineSpeedRMSE_kmph',baselineSpeed, ...
    'baselineMeasuredSpeedRMSE_kmph',baselineMeasuredSpeed, ...
    'candidates',[],'selectionNote','Selection uses first 60%; acceptance checks remaining 40%. Same recording, not independent validation.');
out=baseline; selected=disabled;
if nnz(train)<20||nnz(validation)<20
    report.status='disabled_insufficient_moving_data';
elseif baselineSpeed>speedTolerance || baselineMeasuredSpeed>speedTolerance
    report.status='disabled_speed_tracking_inadequate';
else
    baseTrain=sqrt(mean(z0(train,32).^2)); baseValidation=sqrt(mean(z0(validation,32).^2));
    factors=[0.75 1.5 3];
    if ~opt(options,'AutoTune',true), factors=1; end
    bestTrain=baseTrain;
    for k=1:numel(factors)
        candidate=Comp; candidate.Tau=baseTau*factors(k);
        trial=sim(in.setVariable('Comp',candidate,'Workspace',model));
        z=trial.logout.signals.values;
        trainRMS=sqrt(mean(z(train,32).^2)); validationRMS=sqrt(mean(z(validation,32).^2));
        speedRMS=sqrt(mean((z(:,1)-z(:,16)).^2));
        saturationFraction=mean(abs(z(moving,30))>=0.98*candidate.Limit);
        measuredSpeedOK=true;
        if isfield(d,'measuredSpeed_kmph')
            measuredSpeedOK=sqrt(mean((z(:,16)-alignedMeasuredSpeed).^2))<=speedTolerance;
        end
        accepted=all(isfinite(z),'all') && trainRMS<0.98*baseTrain && ...
            validationRMS<=1.02*baseValidation && speedRMS<=speedTolerance && ...
            speedRMS<=baselineSpeed+max(0.5,0.25*baselineSpeed) && saturationFraction<0.05 && measuredSpeedOK;
        report.candidates=[report.candidates; candidate.Tau trainRMS validationRMS speedRMS saturationFraction accepted]; %#ok<AGROW>
        if accepted&&trainRMS<bestTrain
            bestTrain=trainRMS; out=trial; selected=candidate; report.status='accepted';
        end
    end
end
logout=out.logout;
logout.signalNames=getVariable(mw,'SignalNames');
logout.sourceTime=logout.time+timeOffset;
for j=1:numel(logout.signalNames)
    logout.data.(logout.signalNames{j})=logout.signals.values(:,j);
end
z=logout.signals.values;
assert(all(isfinite(z),'all')&&size(z,2)==numel(logout.signalNames));
assert(max(abs(z(:,22)-sum(z(:,18:21),2)-z(:,34)))<1e-5,'Traction force balance.');
assert(max(abs(z(:,18)-(z(:,23)-z(:,24)-sum(z(:,19:21),2)-z(:,34)+z(:,25))))<1e-5,'Newton force balance.');
assert(max(z(:,11))<=P.MotorCount*P.MotorPower/1000+1e-6);
assert(min(z(:,11))>=-P.MotorCount*P.RegenPower/1000-1e-6);
assert(min(z(:,15))>=-1e-8&&all(z(:,4:5)>=-1e-8 & z(:,4:5)<=100+1e-8,'all'));
assert(max(z(:,9))<=P.MotorPeakTorque+1e-6&&min(z(:,9))>=-P.RegenPeakTorque-1e-6);
assert(all(abs(z(z(:,15)==0,34))<1e-6));
assert(max(abs(z(:,30)))<=selected.Limit+1e-6&&max(abs(z(:,38)))<=selected.MaxRate+1e-6);
report.Comp=selected; report.RMSE_N=sqrt(mean(z(:,32).^2));
report.speedRMSE_kmph=sqrt(mean((z(:,1)-z(:,16)).^2));
report.accepted=strcmp(report.status,'accepted');
report.source= d; % Preserve input metadata and profiles for reproducibility.
if opt(options,'Apply',true)
    assignin(mw,'P',P); assignin(mw,'Comp',selected);
    assignin(mw,'MeasuredTraction',[t force]); assignin(mw,'MeasuredForceBias',bias);
    assignin(mw,'CaseStopTime',duration);
    for j=1:numel(profileNames), name=profileNames{j}; assignin(mw,name,profiles.(name)); end
    save_system(model);
    assignin('base','logout',logout); assignin('base','caseReport',report);
    save(fullfile(folder,'EV_Bus_case_results.mat'),'logout','report');
end
fprintf('%s: RMS %.2f -> %.2f N, noise %.2f N, bias %.2f N, Tau %.3g s\n', ...
    report.status,report.baselineRMSE_N,report.RMSE_N,noise,bias,selected.Tau);
end

function value=opt(s,name,fallback)
if isfield(s,name), value=s.(name); else, value=fallback; end
end
function out=mergeKnown(out,patch)
assert(isstruct(patch)&&isscalar(patch));
names=fieldnames(patch);
assert(all(ismember(names,fieldnames(out))),'Unknown vehicle field. Use names from model workspace P.');
for k=1:numel(names), out.(names{k})=patch.(names{k}); end
end
