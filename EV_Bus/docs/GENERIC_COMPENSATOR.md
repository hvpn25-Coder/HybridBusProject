# Reusable electric-bus case workflow

Use `run_EV_Bus_case.m` for new measurements, speed profiles or vehicle specifications. It configures and runs the same basic-block compensator; no Simulink logic needs to be rebuilt for each recording. `run_EV_Bus.m` remains a convenience plotting example specifically for the supplied 300 s file and its known 0–4 s parked interval.

## One call for a new case

```matlab
options = struct;
options.Vehicle = struct('Mass',24000,'MotorCount',2, ...
    'MotorPower',450e3,'GearRatio',18,'WheelRadius',0.52);
options.StationaryWindow = [100 104]; % Only if known parked/level/zero traction
[logout, report, out] = run_EV_Bus_case('my_recording.mat', options);
```

Use the full file path if necessary. `logout` remains a MATLAB structure, with all 38 output signals and named vectors under `logout.data`. The accepted configuration is embedded in the model and saved, so the Simulink Run button reuses it. `results/EV_Bus_case_results.mat` stores the result and configuration report. For experiments without changing the saved model, set `options.Apply=false`.

Vehicle values are merged with the current model workspace `P`; unspecified values retain their current settings. MotorPower and torque limits are **per motor**, while MaxBrakeTorque is total wheel friction torque. Update peak torque, regenerative capability, motor speed limit and brake capacity as well when they differ on the new vehicle. Changing only rated power cannot infer those specifications. The current saved model is the source of unspecified parameters, not an immutable factory default.

## MAT file contents

Required:

| Variable | Format / units |
|---|---|
| measurementTime | N-by-1 strictly increasing timestamps, seconds |
| measurementForce | N-by-1 signed net wheel traction, newtons |
| SpeedProfile | K-by-2 [timestamp, desired speed in km/h] |
| SlopeProfile | K-by-2 [timestamp, grade in percent] |
| TemperatureProfile | K-by-2 [timestamp, ambient degrees Celsius] |

The three profiles can have their own time grids, but must use the same time origin as measurementTime and cover the entire recording. They are linearly interpolated. Time is internally shifted to zero; `logout.sourceTime` restores the original timestamps. Duration, logging interval and solver maximum step adapt to the recording. At least 50 samples and 10 s are required. Mildly nonuniform sampling is interpolated; duplicate timestamps, NaNs, nonfinite values and gaps >=3 times the median interval are rejected rather than silently patched.

Optional MAT variables:

- `P`: a struct of vehicle-parameter overrides (same field names as model workspace P).
- `measuredSpeed_kmph`: N-by-1 measured speed; provides initial speed and an additional trajectory-consistency check.
- `ForceUnits='N'`, `TimeUnits='s'`: checked if supplied. Numeric units cannot otherwise be inferred.

The older `meas_time` / `meas_traction_froce` naming is also supported. You may provide the three profile matrices through options instead of the MAT file. To intentionally reuse the profiles already in the model, explicitly set `ReuseModelProfiles=true`; coverage is still checked. The runner never silently guesses a new drive cycle from the force trace.

For a recording starting in motion, provide `options.InitialSpeed_mps` or measuredSpeed_kmph. A nonzero target alone is not used as a measured initial speed. Distance starts at zero for each case.

## Bias is an explicit choice

Choose ONE:

```matlab
options.StationaryWindow = [t1 t2]; % Original recording timestamps
% OR
options.Bias_N = calibratedSensorBias;
```

With neither option, zero bias is assumed and the report states that no stationary calibration was performed. StationaryWindow asserts that the vehicle is parked on level ground with zero net traction. The runner checks target speed and grade there, plus measured speed when available, and uses a robust trimmed mean. It does not presume every stop has zero traction, or presume the first four seconds are stopped. If you have no such interval, use a known calibration or leave bias zero and investigate any persistent offset independently.

## Automatic configuration and acceptance

For each recording the runner:

1. Estimates fast noise robustly from first differences; when a stationary calibration window is provided, also considers its robust spread. Noise estimation is a heuristic for approximately fast additive noise, not a proof that low-frequency variations are noise. `NoiseSigma_N` overrides it if sensor calibration provides a better value.
2. Scales the force bound using vehicle weight and peak tractive capability. Defaults are `min(0.03*m*g, 0.25*peakWheelForce)`. `ForceLimit_N` overrides this engineering prior when justified.
3. Estimates a nominal driver response time using mass, DriverKp, available motor force at the cycle's representative speed, and actuator time constants.
4. Sets filtering from that response time and sample interval, a noise-scaled deadband, innovation clipping, and a physically scaled maximum adaptation rate.
5. Runs a disabled-compensation baseline and three adaptation candidates at 0.75, 1.5 and 3 times the nominal adaptation time. `AutoTune=false` evaluates one nominal candidate instead.
6. Selects by RMS on moving samples in the first 60% of the recording. It requires >=2% improvement there, no more than 2% worsening on the remaining 40%, acceptable speed tracking, and less than 5% of moving samples at the loss bound. Raw residuals—not filtered error—are used for scoring. The sample mask is shared across candidates.
7. Verifies force balances and power, torque, pedal, force and rate limits using the actual new vehicle specifications.

The second interval is an acceptance check on the same recording, not independent validation of a physical model. For true generalization, bring a separate recording and rerun the checks. There is no global-optimality or universal-stability guarantee.

`report.status` is `accepted`, `disabled_no_accepted_candidate`, `disabled_insufficient_moving_data`, or `disabled_speed_tracking_inadequate`. If compensation cannot demonstrate useful behavior, the returned configuration disables it. Invalid inputs are rejected before simulation. Solver failures raise an error and do not save a candidate. `report.candidates` columns are Tau, training RMS N, validation RMS N, speed RMS km/h, loss-bound fraction, and acceptance flag.

The default speed RMS tolerance is `max(3 km/h, 5% of maximum requested speed)`. `MaxSpeedRMSE_kmph` overrides this criterion. When measured speed is supplied, it is also compared with simulated speed. Without it, compatibility with the actual measured trajectory remains an assumption.

## What stays generic, and what remains limited

The Simulink compensator remains causal: measured/model force residual -> validity and speed gate -> clipping -> low-pass filter -> deadband -> bounded-rate integrator. Case-level configuration/tuning uses the available full recording before deployment. Its settings do not automatically retune online if sensor noise changes halfway through a run; split such regimes into cases or set a conservative noise override.

Positive estimated force is additional opposing load; negative force reduces assumed load. The held estimate fades to zero as vehicle speed falls below MinAdaptSpeed (default 0.5 m/s, configurable). AppliedGenericLoss_N is used in both Newton's law and the logged traction sum. This is a **motion-dependent longitudinal correction**, not an identification of separate rolling, drag and gradient parameters.

Supported scope is forward travel, no tire slip, the existing PI driver, and the existing reduced-order electric/pneumatic actuators. Reverse driving, unknown time offsets, unsigned force magnitudes, tire-slip events, drivetrain faults, unsynchronized reference cycles, sensor drift, or a different definition such as motor-only wheel force need explicit model/data changes. A force-only trace cannot distinguish these from a resistance error. The current model also has no battery SOC/thermal limits. These boundaries prevent a truthful promise that it will work in every condition.

## Checks performed

`tests/check_EV_Bus_generic_cases.m` creates and exercises self-contained cases in `results/generic_case_examples` with changed mass, motor count/power, gearing, profile, duration, sampling, grades and noise. Each has a known synthetic physical correction and uses the actual Simulink plant.

| Case | Main changes | Baseline RMS | Compensated RMS |
|---|---|---:|---:|
| 1 | 12 t, one 250 kW motor, ratio 14, 120 s, 20 ms, 100 N noise | 655 N | 115 N |
| 2 | 28 t, two 500 kW motors, ratio 25, 160 s, 50 ms, 600 N noise | 1671 N | 617 N |
| 3 | Starts at 30 km/h, timestamps start at 100 s, 100 s duration, negative correction, 300 N noise | 1115 N | 317 N |

All were accepted, with force and capability checks passing. Duplicate timestamps were rejected. These are bounded synthetic regression cases, not evidence covering all possible vehicles. Existing noisy data also passed automatic selection (approximately 948 N disabled-compensation RMS to 443 N with automatic configuration).
