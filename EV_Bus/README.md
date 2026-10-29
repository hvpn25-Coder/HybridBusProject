# Electric bus forward model

Start with `run_EV_Bus.m` in MATLAB to run the supplied measurement case and plot the results. Open `EV_Bus_Forward.slx` to inspect the model or run its embedded configuration.

## Folder guide

| File or folder | Purpose |
|---|---|
| `EV_Bus_Forward.slx` | Current forward model and physical traction compensator |
| `run_EV_Bus.m` | Runs and plots the supplied example |
| `run_EV_Bus_case.m` | Reusable entry point for other recordings, profiles and vehicle specifications |
| `Veh_Meas_Traction_Force.mat` | Original supplied measurement file |
| `Analysis.m` | Your existing analysis/noise-generation scratch script, preserved unchanged |
| `docs/` | Current illustrated explanation and case-runner reference |
| `results/` | Latest saved simulation result and plots; future run outputs also go here |
| `tests/` | Regression script for different vehicles, sampling rates and noise levels |
| `_archive/` | Superseded backups, notes, scripts and generated files; not needed by the current workflow |

## Documentation

- [Illustrated compensator explanation](docs/Compensator_Explained.html): equations, physical feedback, noise handling, interactive example and results.
- [Reusable case workflow](docs/GENERIC_COMPENSATOR.md): measurement format, options, scaling, acceptance checks and limitations.

The example wrapper assumes the supplied 300-second recording and its known parked calibration interval of 0–4 seconds. For another recording, call `run_EV_Bus_case` with corresponding profiles, vehicle parameters and appropriate bias calibration; do not reuse that parked interval blindly.

## Model and outputs

The vehicle has a mass of 20,000 kg, two 400 kW motors and a 21:1 final drive. Parameters and environment profiles are embedded in the model workspace. The model uses basic Simulink blocks, with no MATLAB Function blocks.

The forward path is Environment → Driver → Powertrain Controller → Electric Drive → Final Drive → Vehicle Dynamics, with pneumatic friction braking and speed feedback. The signed generic loss acts in the vehicle dynamics; the driver's response changes the physical wheel traction force.

Wheel traction = acceleration force + gradient force + rolling resistance + aerodynamic drag + applied generic loss. At standstill, the applied generic loss fades to zero and an ideal reaction prevents reverse motion. Reverse driving, tire slip, battery SOC and thermal dynamics are outside this model.

All 38 subsystem outputs are logged in the structure `logout`. The case runner also adds signal names and named vectors under `logout.data`. Logging sample time is selected for the supplied measurement.

`results/EV_Bus_case_results.mat` is the single saved result, containing `logout` and `report`. The example wrapper additionally writes `EV_Bus_results.png` and `EV_Bus_compensation.png` into `results/`; its extra summary `metrics` remain in the MATLAB workspace. These files are overwritten on subsequent runs. To experiment without saving a new model configuration or result file, use `options.Apply=false` with the case runner.

Run the regression script from the project root:

```matlab
run('tests/check_EV_Bus_generic_cases.m')
```

It writes generated cases under `results/generic_case_examples/`.

## Cleanup note

Obsolete files were moved to `_archive` because automatic approval review blocked permanent deletion. The current workflow does not require them. MATLAB may regenerate its own `slprj` folder or `.slxc` cache during future simulations.