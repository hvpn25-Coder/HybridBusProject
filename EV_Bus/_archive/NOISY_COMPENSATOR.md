# Updated compensator for the noisy recording

**Superseded setup workflow:** use [GENERIC_COMPENSATOR.md](GENERIC_COMPENSATOR.md) for new cases. The figures and tuning below record the previous manually tuned noisy-data version.

This is the current configuration. The earlier results in COMPENSATOR.md refer to the previous measurement file and previous controller.

## Findings and measured improvement

The updated file uses `measurementTime` and `measurementForce` in seconds and newtons. The importer now supports both these names and the original `meas_time` / `meas_traction_froce` names. It preserves your updated data file. Initial stationary bias is +1114.304418 N, estimated from 0–4 s. This still assumes that interval is stationary, flat-road, zero net traction, as in the matching speed cycle.

The new data has approximately 299 N standard deviation in the initial stationary interval. A first-difference estimate of its fast noise is about 292 N. It also contains a genuine time-varying mismatch of several thousand newtons relative to the original simulation. The former 20 s adaptation was too slow to follow it, and its held loss estimate was applied even when parked.

The previous model was rerun with the updated data before editing. The following comparison uses identical measurements, stationary bias correction, and time grid; the moving comparison uses the same sample mask from the previous run. No filtering is applied to the signals used to calculate these RMS errors.

| Metric | Previous | Updated |
|---|---:|---:|
| Full-trace traction RMS error | 807.78 N | 433.61 N |
| Traction RMS on identical moving samples | 869.40 N | 430.43 N |
| Speed-tracking RMS | 1.018 km/h | 1.077 km/h |

Full-trace force error decreased by about 46%; moving force error decreased by about 50%. Improvement occurs in both halves of the recording: approximately 1014 to 523 N for the first 150 s, and 527 to 320 N for the second 150 s. These halves are diagnostics, not an independent holdout: controller settings were explored using this recording.

There is a small speed-tracking tradeoff because the physical load now changes more quickly. Peak loss estimate is about 2743 N, below the 5000 N bound. Some stop-transition and other transient errors remain; maximum instantaneous residual is about 6302 N. Matching noisy samples exactly would inject measurement noise into the vehicle's physical force; this controller targets the underlying changing load instead.

## New basic-block signal path

1. Subtract stationary calibration bias from the raw measurement.
2. Form residual = debiased measurement - simulated physical traction.
3. Gate the residual while speed <=0.5 m/s or outside the measurement interval.
4. Clip that innovation to +/-4000 N to limit the influence of large transients/outliers.
5. Low-pass filter it with a 0.2 s time constant.
6. Apply a +/-20 N dead zone and gate adaptation again at standstill.
7. Integrate with adaptation time constant 1 s, with derivative limited to +/-1500 N/s and integral state limited to +/-5000 N.

The original 20 s adaptation was compared with 1, 2, 3 and 5 s candidates. Additional 0.5 and 0.75 s runs gave only small further force-error improvements; 1 s was retained as the more conservative response with independent noisy-load verification. These settings are engineering tuning for this model, not a guaranteed global optimum.

The estimate is retained while stopped, but the physical force applied is now:

```
AppliedGenericLoss_N = GenericLossForce_N * clamp(speed / 0.5, 0, 1)
```

Thus the applied correction is zero at rest and fully active above 0.5 m/s. This is a low-speed model assumption for motion-dependent generic resistance. Static grade or parking-load errors should be modeled separately rather than identified by this parked-force correction.

Both force equations use **AppliedGenericLoss_N** consistently:

```
Ftraction = m*a + Frolling + Faerodynamic + Fgradient + AppliedGenericLoss
m*a = Fdrive - Ffriction - Frolling - Faerodynamic - Fgradient
      - AppliedGenericLoss + StandstillReaction
```

No MATLAB Function blocks are used. All estimation logic uses ordinary products, gains, sums, saturation, a transfer function, a dead zone, an integrator, and comparisons.

## Running, settings and logging

Run `run_EV_Bus.m` normally. The measurement and calibrated bias are embedded in the saved model too, so the Run button works without an external initialization step. Reimport a changed file through `prepare_EV_Bus_measurement.m` or the run script; save the model to persist the new embedded data.

`Comp` in the model workspace contains the settings. Current values: Tau=1 s, FilterTau=0.2 s, ErrorClip=4000 N, MaxRate=1500 N/s, Deadband=20 N, Limit=5000 N, MinAdaptSpeed=0.5 m/s, InitialForce=0, Enable=1. Setting Enable=0 removes the applied correction and freezes estimation.

All outputs remain in the MATLAB structure `logout`. There are now 38 columns. Columns 1–36 retain their previous order. Column 37 is FilteredError_N (gated and clipped residual after filtering); column 38 is AdaptationRate_Nps. The original raw measured force and raw residual are still logged, so filtering does not conceal error. Column 30 is the held estimate; column 34 is the physical force after the low-speed fade. Use the latter in the force balance.

`compare_EV_Bus_noise_update.m` reproduces the comparison with the saved pre-update simulation. It explicitly rejects a changed measurement so that a later recording is not compared against mismatched baseline data. The old model is saved as `EV_Bus_Forward_before_noise_update.slx`, and the old current-recording simulation is `EV_Bus_noisy_before.mat`.

## Verification

- Model connectivity checks: healthy.
- Run-script checks: finite outputs, motor power/torque bounds, pedals, forward-only speed, bounded loss and adaptation rate, zero applied loss at rest, and both force identities.
- Clean independent 1000 N-load check: estimated 980 N, with 20 N residual consistent with the explicit dead zone.
- Independent seeded 300 N Gaussian noise with intermittent +8000 N impulses and known changing loads: average estimates 1010.56 N for a +1000 N plateau and -796.25 N for a -800 N plateau.

Run `check_EV_Bus_compensator.m` to repeat those checks. They verify controller operation; predictive performance still needs a separate vehicle recording with synchronized speed/grade conditions. A traction residual alone cannot uniquely identify which resistance parameter is wrong.
