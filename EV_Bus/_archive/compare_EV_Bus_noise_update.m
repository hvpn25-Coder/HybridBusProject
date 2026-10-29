% Compare the saved pre-update simulation with the current model on the same data.
modelFolder = fileparts(mfilename('fullpath'));
run(fullfile(modelFolder,'run_EV_Bus.m'));
before = load(fullfile(modelFolder,'EV_Bus_noisy_before.mat'),'oldOut');
oldValues = before.oldOut.logout.signals.values;
oldTime = before.oldOut.logout.time;
assert(isequal(oldTime,logout.time),'Comparison needs the same time grid.');
assert(max(abs(oldValues(:,35)-x(:,35)))<1e-6,'Measurement changed: rerun old model for a fair comparison.');
commonMoving = oldValues(:,15)>0.5;
comparison = table([sqrt(mean(oldValues(:,32).^2));sqrt(mean(x(:,32).^2))], ...
    [sqrt(mean(oldValues(commonMoving,32).^2));sqrt(mean(x(commonMoving,32).^2))], ...
    [sqrt(mean((oldValues(:,1)-oldValues(:,16)).^2));sqrt(mean((x(:,1)-x(:,16)).^2))], ...
    'VariableNames',{'AllSampleRMS_N','SameMovingSamplesRMS_N','SpeedRMS_kmph'}, ...
    'RowNames',{'Previous','Updated'});
disp(comparison);
save(fullfile(modelFolder,'EV_Bus_noise_comparison.mat'),'comparison','logout');
figure('Name','Noisy traction: before and after','Color','w','Position',[100 80 1200 900]);
tiledlayout(3,1,'TileSpacing','compact');
nexttile; plot(logout.time,[x(:,35) oldValues(:,22) x(:,22)]/1000); grid on;
ylabel('Force (kN)'); legend('Debiased measurement','Previous physical model','Updated physical model');
title('Same noisy recording; no smoothing of the reported measurement');
nexttile; plot(logout.time,[oldValues(:,32) x(:,32)]); grid on;
ylabel('Error (N)'); legend('Previous','Updated');
title(sprintf('All-sample RMS: %.1f N to %.1f N',comparison.AllSampleRMS_N));
nexttile; plot(logout.time,[oldValues(:,30) x(:,30) x(:,34)]); grid on;
xlabel('Time (s)'); ylabel('Generic force (N)');
legend('Previous estimate','Updated estimate','Updated applied force');
exportgraphics(gcf,fullfile(modelFolder,'EV_Bus_noise_comparison.png'),'Resolution',150);
