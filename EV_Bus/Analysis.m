% clc, close all
figure
plot(logout.data.Vehicle_Dynamics_WheelTractionForce_N)
hold on
plot(logout.data.Vehicle_Dynamics_GradientForce_N+logout.data.Vehicle_Dynamics_RollingResistanceForce_N+...
    logout.data.Vehicle_Dynamics_AerodynamicForce_N+logout.data.Vehicle_Dynamics_AccelerationForce_N,'LineStyle','--')


 

% 2. Choose your noise percentage (e.g., 10% which is right between 5% and 15%)
noise_percentage = 0.01; 

% 3. Calculate the noise amplitude based on the signal's peak
signal_peak = max(abs(logout.data.Vehicle_Dynamics_WheelTractionForce_N));
noise_amplitude = noise_percentage * signal_peak;

% 4. Generate Gaussian random noise matching the size of your signal
noise = noise_amplitude * randn(size(logout.data.Vehicle_Dynamics_WheelTractionForce_N));

% 5. Add the noise to your original signal
noisy_signal = logout.data.Vehicle_Dynamics_WheelTractionForce_N + noise+1000;

% 6. Visualise the result
plot(logout.data.Vehicle_Dynamics_WheelTractionForce_N, 'LineWidth', 2); hold on;
plot(noisy_signal, 'k--');
legend('Original Signal', 'Noisy Signal (10%)');
grid on;
