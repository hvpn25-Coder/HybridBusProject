# Forward electric bus model

**Reusable case workflow:** [GENERIC_COMPENSATOR.md](GENERIC_COMPENSATOR.md) describes the current entry point `run_EV_Bus_case.m` for new measurement files, vehicle parameters, profile lengths and noise levels. It automatically scales and assesses compensator settings. Earlier pages describe prior configurations.

**Current noisy-data update:** see [NOISY_COMPENSATOR.md](NOISY_COMPENSATOR.md). Logging now has 38 signals, with filtering, bounded adaptation rate, and standstill fading of the physical generic loss. Earlier descriptions below are retained as baseline documentation.

**Updated with measured-force compensation:** see [COMPENSATOR.md](COMPENSATOR.md) for stationary bias removal, the physical generic-loss estimator, new logging columns, and measured results. The model now logs 36 signals; the original 28 retain their column order. The equations below describe the original baseline; the updated force balance additionally includes GenericLossForce_N.

Open `EV_Bus_Forward.slx` and press Run, or run `run_EV_Bus.m` to simulate, verify force/power bounds, save results, and plot the drive cycle. Built with the MATLAB Simulink MCP server in R2025a. Only basic Simulink blocks are used; there are no MATLAB Function blocks, Stateflow charts, S-functions, Simscape components, or external runtime dependencies.

All parameters are embedded in the model workspace as `P`; environment inputs are `SpeedProfile`, `SlopeProfile`, and `TemperatureProfile` (two-column time/value matrices, linearly interpolated). Open Model Explorer to edit them. The MAT parameter file is a reference copy; the model does not require it to run.

## Architecture

Environment -> Driver -> Powertrain Controller -> Electric Drive -> Final Drive -> Vehicle Dynamics. Actual vehicle speed feeds back to the driver, while kinematic motor speed feeds back to the torque controller and electric drive. The pneumatic subsystem supplies the friction braking remaining after actual regenerative wheel torque. Vehicle velocity is integrated from net force divided by mass: this is a forward model.

The two identical motors share torque equally and are represented by their combined torque/power envelope and a common shaft speed. Both combined and per-motor torque are logged. Positive torque drives; negative torque regenerates. Per-motor power is half the logged combined mechanical power.

## Specifications and assumptions

| Parameter | Value |
|---|---:|
| Vehicle mass, user specified | 20,000 kg |
| Motors, user specified | 2 x 400 kW |
| Final drive, user specified | 21:1 |
| Peak driving torque | 2,500 Nm per motor |
| Peak regenerative torque | 1,500 Nm per motor |
| Regenerative power ceiling | 250 kW per motor |
| Maximum commanded driving speed | 12,000 motor RPM |
| Wheel rolling radius | 0.50 m |
| Gear efficiency | 97% in either power direction |
| Drag coefficient / frontal area | 0.65 / 8 square metres |
| Rolling resistance coefficient | 0.008 |
| Motor torque time constant | 0.05 s |
| Maximum total wheel friction brake torque | 60,000 Nm |
| Maximum brake chamber pressure | 8 bar |
| Pneumatic transport delay / time constant | 0.10 s / 0.25 s |
| Initial speed and travelled distance | Zero |
| Electrical supply | Available supply; no battery SOC limitation |

Driver: PI control with limited integral state and saturation feedback, separate 0–100% accelerator/brake outputs, and minimum 15% brake when desired speed is at or below 0.1 km/h. Regeneration fades linearly below 2 m/s, with friction braking supplying the remainder. Pneumatic pressure tracks the requested residual brake torque with delay and first-order chamber dynamics. This is a reduced-order pneumatic model, not a valve/reservoir flow model.

## Forces and sign conventions

With road grade `s` in percent, `theta = atan(s/100)`:

- Gradient force = `m*g*sin(theta)` (positive uphill, negative downhill).
- Rolling force = `m*g*Crr*cos(theta)*tanh(v/0.2)`.
- Aerodynamic force = `0.5*rho*Cd*A*v^2`, with `rho = 101325/(287.05*(ambientC+273.15))`.
- Acceleration force = `m*a`.
- Wheel traction force = acceleration + gradient + rolling + aerodynamic forces.
- Net applied force = motor wheel force minus friction brake force minus gradient, rolling, and aerodynamic forces.

During motion, wheel traction is the signed net tire force after friction braking. Motor wheel force is separately logged as DriveForce_N. At standstill the model prevents reverse motion with an ideal unilateral constraint; its reaction is explicitly logged. Thus traction equals drive force minus friction brake force plus standstill reaction. This also means automatic rollback prevention is assumed, even if the physical parking brake would not hold the grade. Reverse driving, tire slip, wheel rotational inertia, suspension, battery SOC, electrical losses, and thermal dynamics are outside this model. Ambient temperature affects air density only. A speed above the motor RPM limit disables positive torque; it does not impose an artificial vehicle-speed clamp downhill.

## Logging

The model's To Workspace block produces the actual MATLAB **structure** `logout`, using Structure With Time format at 0.01 s intervals. It contains all 28 subsystem outputs:

```matlab
logout.time                 % N-by-1 seconds
logout.signals.values        % N-by-28 output samples
```

Column order is stored as `SignalNames` in the model workspace. Running `run_EV_Bus.m` also adds `logout.signalNames` and convenient named vectors, for example:

```matlab
logout.data.Vehicle_Dynamics_VehicleSpeed_kmph
logout.data.Powertrain_Controller_MotorCommandTotal_Nm
logout.data.Pneumatic_Brake_FrictionBrakeTorque_Nm
```

The model's Run button places `logout` directly in the base workspace. The script uses SimulationInput/SimulationOutput, extracts `out.logout` into `logout`, and saves it to `EV_Bus_results.mat`. Basic-block intermediate wires are not separately logged; every subsystem output is logged.

## Default scenario and validation

The 300 s synthetic cycle includes stops, targets up to 60 km/h, grades from -3% to +4%, and ambient temperature from 25 to 35 degrees Celsius. It is an illustrative cycle, not a certified bus drive cycle. The solver uses ode23t, a maximum step of 0.01 s, relative tolerance 1e-5, and absolute tolerance 1e-7.

Structural connectivity checks pass. The run script checks finite outputs, pedal bounds, forward-only speed, combined drive/regeneration power limits, torque bounds, and both the requested traction identity and Newton's force balance. The standard cycle gives approximately 1.0 km/h RMS speed error and 2.38 km travelled.

A separate flat-road stress simulation commanded 100 km/h at 1.01 s, then zero at 60.01 s, ending at 100 s. It reached the 800 kW combined drive limit without exceeding it, regenerated up to 495.83 kW, produced a peak combined driving torque of 4,999.4 Nm, and stopped at zero speed. Its SimulationOutput is saved in `EV_Bus_stress_results.mat`. The nominal profile embedded in the model was not modified.
