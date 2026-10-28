% Check that the physical adaptive loop learns a known additional 1000 N load.
% SimulationInput overrides leave the saved model and measurement untouched.
modelFolder = fileparts(mfilename('fullpath'));
open_system(fullfile(modelFolder,'EV_Bus_Forward.slx'));
modelWorkspace = get_param('EV_Bus_Forward','ModelWorkspace');
testComp = getVariable(modelWorkspace,'Comp');
testComp.Enable = 0;
in = Simulink.SimulationInput('EV_Bus_Forward');
in = in.setModelParameter('ReturnWorkspaceOutputs','on','StopTime','300');
in = in.setVariable('SpeedProfile',[0 0;5 0;25 40;300 40],'Workspace','EV_Bus_Forward');
in = in.setVariable('SlopeProfile',[0 0;300 0],'Workspace','EV_Bus_Forward');
in = in.setVariable('Comp',testComp,'Workspace','EV_Bus_Forward');
in = in.setVariable('MeasuredForceBias',0,'Workspace','EV_Bus_Forward');
out = sim(in);
checkTime = out.logout.time;
referenceForce = out.logout.signals.values(:,22);
additionalForce = 1000*min(max((checkTime-40)/20,0),1);
in = in.setVariable('MeasuredTraction',[checkTime referenceForce+additionalForce], ...
    'Workspace','EV_Bus_Forward');
testComp.Enable = 1;
in = in.setVariable('Comp',testComp,'Workspace','EV_Bus_Forward');
out = sim(in);
checkValues = out.logout.signals.values;
lateSamples = checkTime>200;
lateRMSE = sqrt(mean(checkValues(lateSamples,32).^2));
assert(lateRMSE<testComp.Deadband+3,'Physical compensation did not converge.');
assert(abs(checkValues(end,30)-1000)<testComp.Deadband+3,'Wrong signed load estimate.');
assert(max(abs(checkValues(:,22)-sum(checkValues(:,18:21),2)-checkValues(:,34)))<1e-6);
assert(all(isfinite(checkValues),'all'));
assert(max(abs(checkValues(:,30)))<=testComp.Limit+1e-6);
fprintf('Known 1000 N load: estimate %.3f N; late RMS error %.3f N.\n', ...
    checkValues(end,30),lateRMSE);
save(fullfile(modelFolder,'EV_Bus_compensator_check.mat'),'out','lateRMSE');

% Independent seeded noise and impulse rejection check, including both signs.
rngState = rng;
rng(71);
noise = 300*randn(size(checkTime));
noise(7001:1700:23001) = noise(7001:1700:23001)+8000;
rng(rngState);
knownLoad = 1000*min(max((checkTime-40)/20,0),1) ...
    -1800*min(max((checkTime-150)/20,0),1);
in = in.setVariable('MeasuredTraction',[checkTime referenceForce+knownLoad+noise], ...
    'Workspace','EV_Bus_Forward');
out = sim(in);
z = out.logout.signals.values;
plateau1 = checkTime>100 & checkTime<140;
plateau2 = checkTime>230 & checkTime<290;
assert(abs(mean(z(plateau1,30))-1000)<100,'Positive load under noise.');
assert(abs(mean(z(plateau2,30))+800)<100,'Negative load under noise.');
assert(max(abs(z(:,38)))<=testComp.MaxRate+1e-6);
assert(all(isfinite(z),'all'));
assert(max(abs(z(:,22)-sum(z(:,18:21),2)-z(:,34)))<1e-6);
fprintf('Independent noisy +/- loads: mean estimates %.2f N and %.2f N.\n', ...
    mean(z(plateau1,30)),mean(z(plateau2,30)));
save(fullfile(modelFolder,'EV_Bus_noisy_synthetic_check.mat'),'out','knownLoad','noise');
