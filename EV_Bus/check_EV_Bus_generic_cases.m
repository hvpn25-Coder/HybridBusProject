% Regression across vehicle scale, profile, timestamps, sampling and noise.
% Synthetic cases exercise the real Simulink plant and the case-runner API.
folder=fileparts(mfilename('fullpath'));
open_system(fullfile(folder,'EV_Bus_Forward.slx'));
mw=get_param('EV_Bus_Forward','ModelWorkspace');
originalP=getVariable(mw,'P'); originalComp=getVariable(mw,'Comp');
caseFolder=fullfile(folder,'generic_case_examples');
if ~isfolder(caseFolder), mkdir(caseFolder); end
settings=[12000 1 250e3 14 120 .02 100 0; ...
          28000 2 500e3 25 160 .05 600 0; ...
          20000 2 400e3 21 100 .02 300 100];
summary=cell(3,5);
oldRng=rng; rng(341);
for scenario=1:size(settings,1)
    s=settings(scenario,:); P=originalP;
    P.Mass=s(1); P.MotorCount=s(2); P.MotorPower=s(3); P.GearRatio=s(4);
    duration=s(5); dt=s(6); noiseLevel=s(7); offset=s(8);
    if scenario==3
        P.InitialSpeed=30/3.6;
        SpeedProfile=[0 30;20 30;40 45;65 45;80 25;duration 25];
    else
        P.InitialSpeed=0;
        SpeedProfile=[0 0;5 0;25 35;55 35;75 20;duration 20];
    end
    SlopeProfile=[0 0;30 0;40 2;60 2;75 0;duration 0];
    TemperatureProfile=[0 15;duration 32];
    cc=originalComp; cc.Enable=0; cc.LogSampleTime=dt; cc.MaxStep=min(dt,.01);
    cc.MeasurementEnd=duration;
    in=Simulink.SimulationInput('EV_Bus_Forward');
    in=in.setModelParameter('ReturnWorkspaceOutputs','on','StopTime',num2str(duration));
    names={'P','SpeedProfile','SlopeProfile','TemperatureProfile'};
    vals={P,SpeedProfile,SlopeProfile,TemperatureProfile};
    for k=1:numel(names), in=in.setVariable(names{k},vals{k},'Workspace','EV_Bus_Forward'); end
    in=in.setVariable('Comp',cc,'Workspace','EV_Bus_Forward');
    in=in.setVariable('MeasuredTraction',[0 0;duration 0],'Workspace','EV_Bus_Forward');
    in=in.setVariable('MeasuredForceBias',0,'Workspace','EV_Bus_Forward');
    out=sim(in); reference=out.logout.signals.values; localTime=out.logout.time;
    extra=0.006*P.Mass*P.Gravity*min(max((localTime-12)/10,0),1);
    if scenario==3, extra=-extra; end
    measurementTime=localTime+offset;
    measurementForce=reference(:,22)+extra+noiseLevel*randn(size(localTime))+350;
    measuredSpeed_kmph=reference(:,16);
    SpeedProfile(:,1)=SpeedProfile(:,1)+offset;
    SlopeProfile(:,1)=SlopeProfile(:,1)+offset;
    TemperatureProfile(:,1)=TemperatureProfile(:,1)+offset;
    ForceUnits='N'; TimeUnits='s';
    file=fullfile(caseFolder,sprintf('case_%d.mat',scenario));
    save(file,'measurementTime','measurementForce','SpeedProfile','SlopeProfile', ...
        'TemperatureProfile','P','measuredSpeed_kmph','ForceUnits','TimeUnits');
    opts=struct('Bias_N',350,'Apply',false);
    [caseLog,rep]=run_EV_Bus_case(file,opts);
    assert(rep.accepted,'Expected useful physical compensation for this known-load case.');
    assert(rep.RMSE_N<rep.baselineRMSE_N);
    assert(abs(caseLog.sourceTime(1)-offset)<1e-9);
    assert(rep.duration_s==duration&&abs(rep.sampleTime_s-dt)<1e-9);
    summary(scenario,:)={scenario,rep.status,rep.baselineRMSE_N,rep.RMSE_N,rep.Comp.Tau};
end
rng(oldRng);
disp(cell2table(summary,'VariableNames',{'Case','Status','BaselineRMS','CompensatedRMS','Tau'}));
save(fullfile(caseFolder,'validation_summary.mat'),'summary');
% Verify clear rejections before attempting simulations.
bad=load(file); bad.measurementTime(10)=bad.measurementTime(9);
badFile=fullfile(caseFolder,'invalid_duplicate_time.mat'); save(badFile,'-struct','bad');
rejected=false;
try
    run_EV_Bus_case(badFile,struct('Apply',false));
catch problem
    rejected=contains(problem.message,'timestamps');
end
assert(rejected,'Duplicate timestamps must be rejected.');
fprintf('Three varied physical cases passed; invalid timestamps rejected.\n');
% A parked-only record cannot identify motion-dependent resistance.
parkedCase=load(file);
parkedCase.SpeedProfile(:,2)=0; parkedCase.SlopeProfile(:,2)=0;
parkedCase.P.InitialSpeed=0;
parkedCase.measuredSpeed_kmph(:)=0; parkedCase.measurementForce(:)=0;
parkedFile=fullfile(caseFolder,'parked_only.mat'); save(parkedFile,'-struct','parkedCase');
[~,parkedReport]=run_EV_Bus_case(parkedFile,struct('Apply',false));
assert(strcmp(parkedReport.status,'disabled_insufficient_moving_data'));
assert(parkedReport.Comp.Enable==0);
fprintf('Parked-only record correctly disables unidentifiable adaptation.\n');
