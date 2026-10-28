% Run the self-contained forward electric-bus model and inspect all outputs.
% Parameters and environment profiles are stored in the model workspace.
modelFolder = fileparts(mfilename('fullpath'));
open_system(fullfile(modelFolder,'EV_Bus_Forward.slx'));
[logout, caseReport, out] = run_EV_Bus_case( ...
    fullfile(modelFolder,'Veh_Meas_Traction_Force.mat'), ...
    struct('ReuseModelProfiles',true,'StationaryWindow',[0 4]));
% The window above is specific to this example. For another recording use
% run_EV_Bus_case with its own profiles and explicit bias calibration.
modelWorkspace = get_param('EV_Bus_Forward','ModelWorkspace');
compensationParameters = caseReport.Comp;
MeasuredForceBias = caseReport.bias_N;
vehicleParameters = caseReport.Vehicle;
logout.signalNames = getVariable(modelWorkspace,'SignalNames');
for signalIndex = 1:numel(logout.signalNames)
    logout.data.(logout.signalNames{signalIndex}) = logout.signals.values(:,signalIndex);
end
save(fullfile(modelFolder,'EV_Bus_results.mat'),'logout');

% Verify physical invariants using the actual simulated signals.
x = logout.signals.values;
assert(size(x,2)==38 && all(isfinite(x),'all'),'Missing or nonfinite outputs.');
assert(min(x(:,15)) >= -1e-8,'Vehicle reversed.');
assert(all(x(:,4:5)>=-1e-8 & x(:,4:5)<=100+1e-8,'all'),'Pedal range.');
assert(max(x(:,11))<=vehicleParameters.MotorCount*vehicleParameters.MotorPower/1000+1e-6 && ...
    min(x(:,11))>=-vehicleParameters.MotorCount*vehicleParameters.RegenPower/1000-1e-6,'Motor power limit.');
assert(max(x(:,9))<=vehicleParameters.MotorPeakTorque+1e-6 && ...
    min(x(:,9))>=-vehicleParameters.RegenPeakTorque-1e-6,'Motor torque limit.');
assert(max(abs(x(:,22)-sum(x(:,18:21),2)-x(:,34)))<1e-6,'Traction force balance.');
assert(max(abs(x(:,18)-(x(:,23)-x(:,24)-sum(x(:,19:21),2)-x(:,34)+x(:,25))))<1e-6,'Newton force balance.');
assert(max(abs(x(:,30)))<=compensationParameters.Limit+1e-6,'Loss estimate limit.');
assert(max(abs(x(:,38)))<=compensationParameters.MaxRate+1e-6,'Adaptation rate limit.');
assert(all(abs(x(x(:,15)==0,34))<1e-6),'Applied loss must vanish at rest.');
fprintf('Logged %d signals, %d samples. Speed RMSE %.3f km/h. Distance %.3f km.\n', ...
    size(x,2),size(x,1),sqrt(mean((x(:,1)-x(:,16)).^2)),x(end,26)/1000);

fig = figure('Name','Electric Bus Forward Model','Color','w','Position',[100 80 1200 850]);
tiledlayout(3,2,'TileSpacing','compact');
nexttile; plot(logout.time,x(:,[1 16]),'LineWidth',1.3); grid on;
ylabel('Speed (km/h)'); legend('Desired','Actual'); title('Forward speed tracking');
nexttile; plot(logout.time,x(:,[4 5]),'LineWidth',1.1); grid on;
ylabel('Pedal (%)'); legend('Accelerator','Brake'); title('Driver');
nexttile; plot(logout.time,x(:,[6 8]),'LineWidth',1.1); grid on;
ylabel('Combined torque (Nm)'); legend('Command','Actual'); title('Two-motor drive');
nexttile; plot(logout.time,x(:,[18 19 20 21 34 22])/1000,'LineWidth',1.1); grid on;
ylabel('Force (kN)'); legend('Acceleration','Gradient','Rolling','Aerodynamic','Generic loss','Traction');
title('Longitudinal force balance');
nexttile; plot(logout.time,x(:,27)/1000,'LineWidth',1.1); grid on;
xlabel('Time (s)'); ylabel('Friction torque (kNm)'); title('Pneumatic service brake');
nexttile; plot(logout.time,x(:,11),'LineWidth',1.1); grid on;
xlabel('Time (s)'); ylabel('Mechanical power (kW)'); title('Positive drive / negative regeneration');
exportgraphics(fig,fullfile(modelFolder,'EV_Bus_results.png'),'Resolution',150);

% All samples are included in the primary error metrics, including stops.
metrics.rawRMSE_N = sqrt(mean((x(:,29)-x(:,22)).^2));
metrics.debiasedRMSE_N = sqrt(mean(x(:,32).^2));
metrics.maximumResidual_N = max(abs(x(:,32)));
movingSamples = x(:,15)>compensationParameters.MinAdaptSpeed;
metrics.movingRMSE_N = sqrt(mean(x(movingSamples,32).^2));
metrics.maximumGenericLoss_N = max(abs(x(:,30)));
metrics.stationaryBias_N = MeasuredForceBias;
disp(metrics);
save(fullfile(modelFolder,'EV_Bus_compensation_results.mat'),'logout','metrics');
compFig = figure('Name','Traction force compensation','Color','w','Position',[120 80 1200 850]);
tiledlayout(3,1,'TileSpacing','compact');
nexttile; plot(logout.time,x(:,[29 35 22])/1000); grid on;
ylabel('Force (kN)'); legend('Raw measured','Bias removed','Physical model');
title('Stationary bias removed before physical loss adaptation');
nexttile; plot(logout.time,[x(:,29)-x(:,22) x(:,32)]); grid on;
ylabel('Residual (N)'); legend('Raw measured - model','Debiased measured - model');
title(sprintf('All-sample RMS: raw %.2f N; debiased %.2f N; moving %.3f N', ...
    metrics.rawRMSE_N,metrics.debiasedRMSE_N,metrics.movingRMSE_N));
nexttile; plot(logout.time,x(:,[30 34])); grid on;
legend('Learned loss','Applied loss');
ylabel('Generic loss (N)'); xlabel('Time (s)');
title('Bounded loss estimate; applied loss fades to zero at standstill');
exportgraphics(compFig,fullfile(modelFolder,'EV_Bus_compensation.png'),'Resolution',150);
