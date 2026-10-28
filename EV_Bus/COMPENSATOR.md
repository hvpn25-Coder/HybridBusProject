# Traction measurement compensation

**Historical version:** this page records the first, nearly noise-free measurement update. The current noisy-data compensator and current results are documented in [NOISY_COMPENSATOR.md](NOISY_COMPENSATOR.md).

The model now removes stationary measurement bias first, then adapts a signed generic physical loss force. All logic uses basic Simulink blocks. The original model is preserved as `EV_Bus_Forward_before_compensation.slx`.

## Result for the supplied file

`Veh_Meas_Traction_Force.mat` contains `meas_time` (seconds) and `meas_traction_froce` (newtons), each with 30,001 samples over 0–300 s. Times are finite, strictly increasing, and spaced by 0.01 s. The file aligns directly with the original synthetic drive cycle; no time shift was fitted.

Relative to the saved original simulation, the measurement has a nearly constant -1199.4 N offset, with about 0.345 N standard deviation. Following your instruction, the first 401 samples (0–4 s) are used to estimate the stationary zero bias: **-1199.421851 N**. This assumes the bus is parked on level ground and net traction should be zero during that interval. The file has no measured speed or slope channel, so this condition is inferred from the matching model cycle and your confirmation; it cannot be independently checked from force alone.

The model compares `measured force - stationary bias` with its physical traction force. It does not alter the original measurement file.

Verified on the updated simulation:

| Metric | Result |
|---|---:|
| Raw measurement versus model, full trace RMS | about 1200.5 N |
| Bias-corrected measurement versus model, full trace RMS | 44.45 N |
| Bias-corrected residual while speed >0.5 m/s | 0.346 N RMS |
| Maximum learned generic force magnitude | 0.000487 N |
| Largest residual at a stop transition | about 7699 N |

The full-trace metric includes every sample. A brief outlier near 280.2 s occurs because the ideal forward-only standstill constraint switches force discontinuously: the saved measurement and re-simulated model fall on different sides of that event at one sample. A few nearby low-speed samples also differ. These samples are retained in the plot and RMS calculation. The moving residual is reported separately, not substituted for the full-trace metric.

The improvement for this dataset comes from zero-bias removal. There is no evidence here for a substantial additional physical loss after that correction. The compensator therefore appropriately learns approximately zero instead of fitting the noise or standstill offset.

## Physical equations

Let `L` be GenericLossForce_N and `e` be debiased measured traction minus simulated physical traction.

```
Ftraction = m*a + Frolling + Faerodynamic + Fgradient + L
m*a = Fdrive - Ffriction - Frolling - Faerodynamic - Fgradient - L
```

The existing standstill reaction is added to the second equation when the forward-only constraint is active. Positive L is extra opposing load. Negative L reduces the assumed load; it is a signed correction, not a claim that dissipative losses themselves are negative.

The controller is a bounded integral adaptation:

```
dL/dt = deadzone(e, +/-2 N) / 20 s
```

Integration is enabled only with vehicle speed >0.5 m/s and within the recorded measurement time range. Otherwise the learned force is held. The integral state is limited to +/-5000 N. The integral state breaks direct algebraic feedback and prevents the output from being merely the instantaneous measured trace. The driver changes its torque demand in response to the resulting physical vehicle-speed dynamics.

This loop depends on the existing closed-loop speed driver. It is not an independent identification of rolling resistance, drag, and slope, which cannot be distinguished from one force trace alone. Replaying measured data is calibration on that drive cycle; it does not establish predictive accuracy on another cycle. Use synchronized speed/grade data and a separate recording for further validation. Adaptation is deliberately slower than the driver; retune for different controller dynamics.

## Controls and files

Run `run_EV_Bus.m` to reimport the file, remove its initial stationary bias, simulate, verify the force balance, and create `EV_Bus_compensation.png` and `EV_Bus_compensation_results.mat`.

The model embeds the current measurement and parameters, so it also runs directly from Simulink. To use a changed MAT file, run `prepare_EV_Bus_measurement.m` first; save the model if those imported values should persist. For another recording, revise the stationary calibration interval and environment profiles to match that recording before running. The importer deliberately rejects files that do not cover the default 0–300 s cycle.

Edit `Comp` in the model workspace:

| Field | Default | Meaning |
|---|---:|---|
| Enable | 1 | 0 disables the applied correction and freezes estimation |
| Tau | 20 s | Inverse adaptation gain; larger is slower |
| Deadband | 2 N | Residual dead zone to avoid learning noise |
| Limit | 5000 N | Symmetric integral-state bounds |
| InitialForce | 0 N | Initial estimate; can replay a previously learned constant |
| MinAdaptSpeed | 0.5 m/s | Freeze estimation below this speed |
| MeasurementStart/End | 0/300 s | Valid adaptation time window |

`logout` remains a MATLAB Structure With Time, now containing 36 columns. The original 28 columns retain their order. New columns are:

29. MeasuredTraction_N — original raw file value.
30. GenericLossForce_N — signed learned physical correction.
31. CorrectedTraction_N — physical model traction including the correction (same as column 22).
32. ResidualError_N — debiased measurement minus physical traction.
33. RawDifference_N — direct comparator diagnostic; also uses the debiased input, so equals column 32.
34. AppliedGenericLoss_N — force actually applied in Vehicle Dynamics.
35. DebiasedMeasuredTraction_N — measurement after stationary calibration.
36. StationaryForceBias_N — estimated offset removed from the measurement.

The run script adds named vectors under `logout.data`, including `GenericLossForce_N`, `DebiasedMeasuredTraction_N`, and `ResidualError_N`.

## Verification of nonzero physical compensation

`check_EV_Bus_compensator.m` uses temporary SimulationInput overrides: a flat-road 40 km/h drive, with a known additional 1000 N in the reference force ramped in over 40–60 s. It leaves the saved model profiles unchanged. The learned force reaches **997.995 N**; error over 200–300 s is **2.139 N RMS**, consistent with the configured 2 N deadband. The maximum traction-force identity residual is below 1e-6 N. The synthetic check verifies operation of the loop; it is not additional vehicle measurement validation.
