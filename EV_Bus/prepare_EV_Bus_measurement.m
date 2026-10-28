% Legacy importer ONLY for the supplied example. For generic recordings use
% run_EV_Bus_case(file,options); see GENERIC_COMPENSATOR.md.
% Import the supplied N/s measurement and estimate its stationary zero bias.
% Assumption: the first 0-4 s are parked on level ground with zero net traction.
% Do not use this interval for other recordings unless that condition is true.
modelFolder = fileparts(mfilename('fullpath'));
open_system(fullfile(modelFolder,'EV_Bus_Forward.slx'));
measurement = load(fullfile(modelFolder,'Veh_Meas_Traction_Force.mat'));
if isfield(measurement,'measurementTime') && isfield(measurement,'measurementForce')
    measurementTime = measurement.measurementTime(:);
    measurementForce = measurement.measurementForce(:);
else
    measurementTime = measurement.meas_time(:);
    measurementForce = measurement.meas_traction_froce(:); % Original file spelling.
end
assert(numel(measurementTime)==numel(measurementForce));
assert(all(isfinite([measurementTime measurementForce]),'all'));
assert(all(diff(measurementTime)>0),'Measurement times must increase strictly.');
assert(measurementTime(1)<=0 && measurementTime(end)>=300,'Default cycle needs 0-300 s coverage.');
stationaryWindow = measurementTime>=0 & measurementTime<=4;
assert(nnz(stationaryWindow)>=20,'Insufficient zero-calibration samples.');
MeasuredForceBias = mean(measurementForce(stationaryWindow));
modelWorkspace = get_param('EV_Bus_Forward','ModelWorkspace');
assignin(modelWorkspace,'MeasuredTraction',[measurementTime measurementForce]);
assignin(modelWorkspace,'MeasuredForceBias',MeasuredForceBias);
compensationParameters = getVariable(modelWorkspace,'Comp');
compensationParameters.MeasurementStart = measurementTime(1);
compensationParameters.MeasurementEnd = measurementTime(end);
assignin(modelWorkspace,'Comp',compensationParameters);
fprintf('Stationary bias: %.6f N, using %d samples in 0-4 s.\n',MeasuredForceBias,nnz(stationaryWindow));
