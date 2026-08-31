# Implementation Plan: HybridBusApp

**Architecture:** UIFigure application

**Serialization:** Programmatic App Designer-compatible MATLAB class (`HybridBusApp.m`). This is the documented R2025a fallback requested in the specification; it uses only public `uifigure` components and opens directly from MATLAB.

**Layout:** Explorer — a stable left control panel for database/configuration inputs and a responsive main area with KPI summary, plots, and ranked configurations.

## Structure

- Slightly widened left control grid: database browser; a titled `Mission Inputs` panel that keeps Route, editable load, calculated curb/total mass, and Auxiliary together; component selectors; price/SOE inputs; manual/optimization mode controls; run/cancel/export actions; and progress status.
- Add a `Repeat route until depleted` checkbox. Off preserves the single-cycle study; on repeats the selected speed/grade/auxiliary mission continuously and terminates when the fuel tank is empty and neither battery can provide usable traction energy.
- Add a default-off `Run BEV first, then Hybrid` checkbox for manual simulations. When checked, execute the same mission in explicit BEV-to-Hybrid order, retain both results, show the final Hybrid histories, and report both operating-cost outcomes. When unchecked, execute only the mode selected by the Hybrid/BEV slider.
- Main tab group in workflow order: Powertrain Architecture, Route Map, KPIs, Simulation Analysis, Model Credibility, Optimization Ranking, Signals, and Detailed Plot.
- KPI tab as a nested decision workspace with four subtabs: `Executive Decision`, `Engineering Scorecard`, `Vehicle Performance`, and `Robustness`. The Executive view gives the shortest qualified architecture recommendation; the Scorecard exposes first-principles feasibility gates and like-for-like metrics; Vehicle Performance compares target versus achieved motion and propulsion-limited mission completion; the Robustness view separates nominal evidence from operational scenarios that have not been simulated.
- Simulation Analysis tab: a concise run interpretation header, energy-flow comparison chart, active-battery duty-share chart, and an engineering assessment table covering mission completion, battery limits, regeneration utilization, genset duty, unmet demand, and conservation error.
- Model Credibility tab: release-gate status, explicit evidence and decisions, powertrain concept screening, and a sensitivity tornado-style chart. Failed, unavailable, and not-implemented evidence remains visible instead of being converted into a cosmetic pass.
- Core computation remains in ordinary MATLAB functions outside UI callbacks so batch and test workflows use identical logic.

## Key behaviors

- Load and validate the default or browsed workbook.
- Keep Route, editable load, calculated curb/total mass, and Auxiliary together in one nested, responsive `Mission Inputs` panel.
- Present initial battery SOE inputs as percentages with `%` units while converting to normalized SOE only at the simulation boundary.
- Label operating prices explicitly as `EUR/L` and `EUR/kWh`.
- Display human-readable route names backed by official European Commission VECTO Urban, Suburban, and Coach mission-cycle IDs.
- Retain the 12 historical mass variants in the workbook as reference data, but calculate the active app mass from the 15-tonne base curb, installed hardware, and entered load.
- Add sourced, geographic European coach corridors in the 600-1,000 km range, with human-readable endpoints and stable route IDs in the existing selector.
- Run a selected configuration and display speed, power, genset, fuel, and cost histories; present Battery 1 and Battery 2 SOE on a 0-100 percentage scale with percent-formatted y-axis ticks.
- Scale the Signals and Detailed Plot time axes for human interpretation: use minutes for missions shorter than two hours and hours for missions of two hours or longer. Keep all simulation calculations and fuel integration in seconds, and apply the selected display unit consistently to every plotted signal.
- Add synchronized slider-style `Time / Distance` switches to the Signals and Detailed Plot tabs. Time mode retains adaptive minutes/hours; Distance mode uses cumulative vehicle distance in kilometres. Switching either tab updates both tabs so comparisons always use one common horizontal coordinate.
- Replace the former card-only KPI dashboard with three scan-friendly decision subtabs while preserving the existing summary calculations. Use actual simulation outputs only; never invent the absent architecture in a selected-only run. BEV-only and Hybrid-only runs report a qualified single-architecture assessment, ordered BEV-then-Hybrid runs enable a true side-by-side recommendation, and optimization results are explicitly labelled as the selected best-result architecture rather than a cross-architecture comparison.
- In `Executive Decision`, show mission context, run scope, recommendation/qualification, two architecture columns, and concise `Why this result`, `Alternative value`, and `Decision limits` panels. A cross-architecture winner is chosen only after feasibility; among two feasible results, lower modeled operating cost per kilometre is the primary discriminator, with source energy and terminal reserve shown as supporting evidence rather than silently folded into an opaque score.
- In `Engineering Scorecard`, show four first-principles gates—mission completion, peak-power delivery, energy conservation/terminal reserve, and economics—plus a metric table with value, unit, direction of preference, and BEV/Hybrid values. Display `NOT RUN` wherever an architecture was not simulated. Do not allow cost to override a failed feasibility gate.
- In `Robustness`, plot the available architectures on operating-cost versus source-energy axes, show nominal mission checks, and keep cold-weather, high-auxiliary, and infrastructure scenarios visibly marked `NOT ASSESSED` until dedicated scenario simulations exist. For `Repeat route until depleted`, relabel mission distance as achieved range, identify the controlled depletion endpoint, show fuel/battery exhaustion evidence, and suppress ordinary terminal-reserve pass/fail wording that would misclassify the intended stopping condition.
- In `Vehicle Performance`, plot desired and achieved speed for each executed architecture, compare route completion, speed-tracking compliance, and speed adequacy on a common 0-100% scale, and tabulate distance shortfall, maximum achieved speed, RMS/maximum speed error, time below target, dominant limiting cause, and termination status. Ordered BEV-then-Hybrid runs shall show both architectures side by side. Prescribed-speed backward runs shall state that achievable performance was not evaluated instead of presenting zero tracking error as evidence.
- Provide a `Detailed Plot` tab with a top-row dropdown and one responsive axes. The dropdown selects acceleration, speed, distance, wheel/motor/reduction-gear torque, wheel/motor/battery power, or engine/generator power and redraws immediately from the latest result.
- Add a `Route Map` tab with a top slider-style `2D / 3D` switch, a preserved geographic 2D axes, a latitude-longitude-elevation 3D axes, and a route-information table. Selecting a geographic corridor redraws both views from the same ordered samples; VECTO regulatory cycles explicitly report that no unique real-world geometry exists instead of displaying invented coordinates.
- Store terrain elevation in metres and explicit elevation provenance in each route MAT file's `Geometry` table. Use cached Copernicus DEM GLO-90 samples obtained through Open-Meteo, interpolate only between sourced points for display continuity, and retain OpenStreetMap/OSRM geometry attribution separately. The elevation view is a visualization input and does not silently replace the simulation-grade channel.
- Replace the workbook route sheets with one self-contained `data/routes/<RouteID>.mat` file per route. Store metadata, time-speed-grade mission data, distance-domain data, grade, geometry/elevation, schema version, and stable display order in each file. Reassemble the existing in-memory route tables in the database loader so simulation, optimization, and map consumers remain compatible while routes can be added or replaced independently.
- Replace the Excel battery and motor catalog sheets with one human-readable MATLAB data script per component, using MATLAB-safe filenames such as `data/batteries/BAT_01.m` and `data/motors/MOT_01.m` while retaining `BAT-01` and `MOT-01` inside each record. Each script shall populate a versioned `BatteryData` or `MotorData` structure containing stable storage order and one component record. The loader shall execute only files inside the selected database's sibling component folders, validate their schema and unique IDs, and rebuild the existing `Battery_Catalog` and `Motor_Catalog` tables so selection, scaling, compatibility filtering, optimization, mass calculation, and simulation APIs remain unchanged.
- Discover battery, motor, and genset add-on scripts recursively and accept safe nonnumeric IDs such as `Bat_Series_1`. Compare IDs case-insensitively for duplicate detection, place records without `StorageOrder` after ordered records, preserve additional files when regenerating built-in data, and build explicit genset-to-engine-to-generator assembly links from each self-contained genset file instead of assuming matching numeric suffixes.
- In 3D mode, color the route by elevation, label longitude, latitude, and elevation units, preserve start/destination markers, and show minimum, maximum, and total elevation gain in the information table. Switching back to 2D restores the existing streets basemap without recomputing the route.
- Reveal a second `Elevation / Slope` slider only while Route Map is in 3D mode. Elevation mode uses metres for both vertical position and color; Slope mode derives road grade as 100 times elevation change divided by path-distance change and uses percent for vertical position and color. Keep start/destination markers and report the calculation basis in the route-information table.
- Render every slider-style switch through one reusable labeled-switch treatment: the selected side is blue and semibold, while the unselected side is gray. Refresh this state after every toggle, including synchronized Time/Distance switches.
- Derive display-only torque channels from the logged wheel force, delivered wheel power, tyre radius, final-drive ratio, and directional efficiencies; do not alter the simulation state or controller calculations.
- Provide a `Powertrain Architecture` tab with native vector component icons and three aligned visual lanes: supervisory control at the top, the isolated genset/standby-charging chain in the middle, and the active-battery traction chain below it.
- Make every component block in the Powertrain Architecture tab clickable. Clicking opens a non-modal, consistently formatted component-inspector window with three nested tabs: `Specification Information`, `Component KPIs`, and `Physical Signals`. Preserve the existing database-backed specification table in the first tab. Populate the other tabs only from the most recent simulation result, and show an explicit run-required message when no result exists. For functional blocks without a hardware catalog entry, display the implemented control/power-flow rule and clearly identify ratings that are not parameterized rather than inventing values.
- Tailor component KPIs and signals to physical responsibility: batteries expose throughput, charge/discharge energy, final SOE, peak power, loss estimate, power and SOE histories; motor/inverter exposes electrical and mechanical energy/power and conversion-loss estimate; reduction exposes wheel-side power/torque and driveline loss; genset exposes electrical energy, fuel, runtime, starts, efficiency proxy and power/fuel histories; auxiliaries expose energy/peak/mean power; regeneration and resistor blocks expose recovered, accepted, and dissipated energy/power; vehicle/wheels expose distance, speed, acceleration, wheel demand/delivery and unmet energy; controllers/selectors expose role duty, switching and operating-mode signals. Use `NOT AVAILABLE` with an explanation when the current conceptual model does not log a requested physical quantity such as temperature or electrical voltage/current.
- Keep two vertically stacked plots in every `Physical Signals` inspector tab and place an independent dropdown immediately above each plot. Populate both dropdowns with the component's available signal views so users can compare any two views concurrently. Add cumulative signed energy and cumulative absolute-energy-throughput choices for each logged power view, calculated by time integration in kWh; retain cumulative fuel or distance views where energy is not physically applicable.
- Extend the architecture component inspectors with first-principles electrical and mechanical traces: vehicle distance for `Wheels + vehicle`; motor-pair and per-motor torque plus the instantaneous motoring and regenerative mechanical-power limits for `Motor pair + inverters`; nominal-voltage DC-bus voltage and signed current for `Traction DC bus`; and SOE/temperature-interpolated OCV and terminal-voltage estimates, signed terminal currents, and instantaneous discharge/charge capability for each battery bank. Label voltage/current channels as concept-model estimates because polarization dynamics, switching ripple, cable impedance, and converter dynamics are outside the backward model.
- Keep component inspectors synchronized to the latest completed result. The selected-only result is shown after BEV-only or Hybrid-only execution; after an ordered BEV-then-Hybrid run, use the app's selected/displayed result (Hybrid, matching the main signal plots) and state that scope in the inspector. Repeat-to-depletion runs use achieved-range and depletion-endpoint wording where relevant.
- Add a blue/gray `Hybrid / BEV` selector at the top of Powertrain Architecture. Hybrid remains the default and preserves the isolated standby-charging architecture. BEV removes the genset/fuel path, connects Battery 1 alone or both voltage-compatible batteries to the traction bus, and redraws the diagram and explanatory note immediately.
- Add a numeric `Battery set multiplier` configuration input. Hybrid mode accepts positive integers: one set is one active Battery-1 pack plus one standby Battery-2 pack, and each additional set duplicates both role banks. BEV mode accepts positive half-set increments: 0.5/1.0/1.5/2.0 sets connect 1/2/3/4 packs. Odd BEV totals assign the additional pack to the Battery-1 selection. Default is 1.0 set.
- Replace the fixed total-mass catalog selector in Mission Inputs with an editable `Load (tonnes)` field and read-only `Calculated curb mass (tonnes)` and `Total vehicle mass (tonnes)` displays. Calculate curb mass from a 15,000 kg base vehicle plus all installed battery packs plus the selected genset assembly in Hybrid mode; omit genset mass in BEV mode. Calculate total mass as curb mass plus the entered load, and refresh it immediately when powertrain mode, battery selections, genset selection, battery-set multiplier, or load changes.
- Use the calculated total mass for MATLAB simulation, both Simulink models, optimization, KPI context, component specifications, and exported results. Retain `Bus_Mass_Catalog` only as a legacy/reference dataset rather than an active app selector.
- Remove the BEV `Use both batteries` checkbox. In BEV mode, initialize all connected packs to the same 85% SOE, keep the two displayed SOE inputs synchronized, disable the genset selector, and derive connected-pack count solely from the set multiplier.
- Extend simulation input, optimization overrides, component mass, available battery energy, charge/discharge current limits and derived power capability, range calculations, summary metadata, component specification dialogs, and Simulink workspace parameters with `BatterySetMultiplier` and deterministic Battery-1/Battery-2 pack counts. Parallel BEV banks share discharge and regenerative charge in proportion to instantaneous bank capability. Hybrid role switching continues between equal-sized active and standby banks, while the isolated genset remains at its single best-efficiency power point.
- Add an editable `HybridBus_BEVModel.slx` using the same route, vehicle, motor, battery, auxiliary, final-drive, and price parameters as the common database. Its top-level interfaces shall expose the two battery paths, parallel BEV energy manager, traction demand, regenerative allocation, and logging without an engine-genset subsystem.
- Route regenerative power with an explicit first-priority order: satisfy DC auxiliary loads, charge only the active battery within its instantaneous power/SOE limits, then dissipate all remaining regenerative power in a resistor load bank. Expose the three allocations in simulation results and energy KPIs.
- Implement blended service braking in both powertrains. Regenerative braking remains the first wheel-braking source up to motor, inverter, battery, speed, and SOE constraints; an explicit pneumatic/friction-brake path supplies the remaining negative wheel-power demand. Log regenerative wheel-brake power, pneumatic-brake power, total delivered braking power, cumulative pneumatic-brake dissipation, and the braking-power balance. Because this is a prescribed-speed backward model, represent the pneumatic system as an ideal residual-demand actuator and state that pressure build-up, fade, ABS/EBS modulation, tyre adhesion, and thermal limits require a later forward-dynamics brake model.
- Show the pneumatic brake as a separate clickable component connected mechanically at the wheels in both Hybrid and BEV architecture views. Its inspector shall expose the residual-demand control law, friction-brake energy, peak power, braking share, power history, and cumulative dissipated energy. Add friction-brake and blended-braking views to the main Signals and Detailed Plot tabs.
- Show the resistor load bank and the 1-2-3 regeneration priorities in the architecture tab without adding crossing connections; include load-bank power in the app's power-flow display.
- Keep charging branches orthogonal and terminate them directly at Battery 1 and Battery 2; no energy or control line may pass through a component box.
- Show the complete blue regeneration path in physical order: wheels and vehicle to fixed reduction, then motor pair and inverters. From the inverter DC side, show numbered branches to auxiliary loads first, the traction DC bus and active battery second, and the resistor load bank third. Use offset forward and reverse arrows between drivetrain blocks so traction and regeneration directions remain visually distinct. Limit supervisory graphics to two dashed command links terminating at the standby and active selectors.
- Remove floating explanatory labels from the flow field. Use left-aligned lane titles, a compact bottom legend, and the existing tab note for interpretation. Keep the diagram static and independent of simulation results.
- Open on Powertrain Architecture by creating it as the first tab, followed by Route Map, KPIs, Optimization Ranking, Signals, and Detailed Plot.
- Increase the sidebar width from 310 px to 350 px so database paths and geographic route names are more legible while preserving most of the architecture canvas.
- Run bounded base-MATLAB configuration searches and honor cancellation between simulations.
- Export selected results to MAT and CSV.

## Internal references used

- `references/uifigure/guide.md`: component and responsive grid conventions.
- `references/uifigure/grid-layout.md`: nested grid sizing.
- `references/uifigure/containers.md`: tab-group and panel organization.
- `references/uifigure/callbacks.md`: callback/data-sharing patterns.
- `references/uifigure/components.md`: dropdown and axes component conventions.
- `references/uifigure/containers.md`: additional tab and nested-grid structure.
- `references/uifigure/layout-patterns.md`: explorer/sidebar structure.
- `references/archetypes/explorer.md`: primary task and spatial skeleton.
- `references/archetypes/dashboard.md`: KPI-card hierarchy inside the Explorer's KPI tab.
- `matlab-theming`: centralized semantic colors and restrained status/accent styling.
- `matlab-build-chart/references/axes-config.md`: axes labels, legends, and explicit axes targeting.
- `matlab-build-chart/references/plot-types.md`: single- and multi-series time-history plots.
- `matlab-build-chart/references/annotations.md`: uifigure-compatible vector shapes, labels, and flow overlays.

## Files

- `HybridBusApp.m`: UI class.
- `src/run_hybrid_bus_simulation.m`: manual run entry point.
- `src/optimize_hybrid_bus_configuration.m`: bounded search entry point.
- `src/export_hybrid_bus_results.m`: MAT/CSV export.
- `data/gensets/GEN_01.m` ... `GEN_12.m`: one complete, versioned engine-generator assembly per file, including the engine fuel and generator efficiency maps.

## Implementation sequence

1. Build and validate the reusable data/simulation functions.
2. Create the explorer layout with `uigridlayout` only.
3. Bind callbacks to the reusable functions.
4. Add standard plots and the dropdown-driven detailed-plot tab, then ranked table, progress/cancel, and export.
5. Launch the app in R2025a and execute a manual run.
6. Render the architecture tab at the normal 1400 x 820 app size and visually verify that blocks, labels, and interconnections do not overlap.
7. Exercise auxiliary-first, active-battery-second, and full-battery load-bank cases and verify DC energy conservation.
8. Verify the Route Map switch in both positions, confirm all geographic routes have finite elevations with unchanged coordinate ordering, and visually inspect representative urban and long-distance 3D routes.
9. Click every Powertrain Architecture block before and after simulation. Confirm each inspector has Specification Information, Component KPIs, and Physical Signals tabs; pre-run result tabs show a run-required message; post-run battery, motor, reduction, genset, auxiliary, regeneration, resistor, vehicle, and controller views contain only relevant metrics/signals with correct units and no invented channels. Verify both physical-signal dropdowns update their respective axes independently and that every cumulative-energy option has the same sample count as the simulation time vector.
10. For Hybrid and BEV results, verify vehicle distance is monotonic; motor torque and both dynamic motor power-limit arrays are finite and nonnegative where applicable; battery voltage/current reconstruct terminal power within numerical tolerance; battery discharge/charge current limits match the same SOE-, temperature-, voltage-, resistance-, and energy-bound equations used by `battery_step`; and DC-bus voltage/current reconstruct signed bus power. Verify the new views appear in the appropriate architecture-block dropdowns.
10. Verify 2D hides the Elevation/Slope control, 3D reveals it, both 3D quantities redraw with correct units, all route-slope samples are finite, and every switch uses blue for its selected label and gray for its unselected label.
11. Verify Hybrid rejects fractional multipliers, BEV accepts only half-set increments, 0.5-set BEV leaves Battery 2 disconnected, 1.5-set BEV represents two Battery-1 packs plus one Battery-2 pack, energy and power capability scale with pack count, Hybrid/BEV switching preserves the appropriate SOE defaults, BEV fuel use is exactly zero, regeneration conserves energy, and both Simulink models remain structurally healthy.
12. Verify the mass identity `total = 15000 kg + installed battery mass + Hybrid genset mass + load` for Hybrid and BEV, confirm multiplier changes scale battery contribution, confirm BEV excludes the genset, and confirm the same calculated total reaches the MATLAB kernel and Simulink workspace.
13. Verify every KPI subtab in four manual-run states: BEV selected only, Hybrid selected only, ordered BEV-then-Hybrid, and each of those with repeat-until-depleted enabled. Confirm unavailable comparison cells say `NOT RUN`, comparison recommendations are feasibility-first, repeat runs use range/depletion semantics, and unexecuted robustness scenarios remain `NOT ASSESSED`.
14. Exercise light braking, regeneration-limited high-deceleration braking, full-battery braking, and zero-speed samples. Verify at every braking sample that requested wheel braking equals regenerative wheel braking plus pneumatic friction braking plus any explicitly reported unmet braking; verify friction braking is nonnegative, inactive in traction, and logged equivalently by the MATLAB, Hybrid Simulink, and BEV Simulink implementations.
15. For every battery file, verify monotonic SOE and temperature breakpoints, nonnegative charge/discharge current maps, positive resistance, cold-temperature derating, upper-SOE charge taper, and terminal power and ohmic-loss identities. Confirm both Simulink battery subsystems use two connected n-D current lookup blocks, current-to-power conversion, and dynamic saturation.

## Forward performance formulation extension

**Architecture:** Existing programmatic UIFigure Explorer with a selectable
simulation formulation. The prescribed-speed backward calculation remains the
default engineering energy-demand mode; `Forward performance` closes the loop
through driver demand, component limits, delivered wheel force, and vehicle
longitudinal dynamics.

**User-visible behavior:**

- Add a `Simulation formulation` switch to Configuration with `Backward demand`
  and `Forward performance` choices.
- Treat route speed as the driver target in performance mode. Use actual travelled
  distance to interpolate target speed and road grade, so falling behind schedule
  does not skip terrain.
- Limit delivered traction and regeneration using the existing motor torque-speed,
  DC conversion-loss, battery current/OCV/resistance/SOE, battery energy, and
  genset-isolation rules before calculating actual acceleration.
- Integrate actual acceleration to nonnegative vehicle speed and monotonically
  increasing distance. If available traction cannot overcome a positive grade,
  hold the vehicle at zero instead of allowing rollback, and report the mission as
  incomplete when forward progress cannot resume.
- Preserve pneumatic/friction braking as the residual service-brake actuator and
  derive it from actual vehicle state in performance mode.
- Plot desired and achieved speed together and expose route completion, speed error,
  time below target, achieved maximum speed, actual completion time, and limiting
  cause in the result summary/KPI data.

**Files:**

- `src/simulate_hybrid_bus_performance.m`: reusable forward longitudinal kernel.
- `src/run_hybrid_bus_simulation.m` and `src/run_powertrain_sequence.m`: formulation routing.
- `HybridBusApp.m`: formulation switch and desired-versus-achieved plotting.
- `models/HybridBus_PerformanceModel.slx`: editable forward vehicle/driver model.
- `tests/forwardPerformanceTest.m`: physics, limiting, distance-domain terrain,
  no-rollback, and backward-mode preservation tests.

**Implementation sequence:**

1. Define a common result contract so backward and performance formulations feed
   the same app, inspectors, export, and comparison workflow.
2. Implement and unit-test actual-distance route interpolation, driver control,
   component-constrained wheel power, longitudinal force balance, integration, and
   route-completion logic in MATLAB.
3. Add the formulation switch and performance displays without changing the
   existing Explorer layout pattern.
4. Build the editable Simulink performance model from standard blocks, verify its
   graph and connectivity, and run configured Hybrid and BEV simulations.
5. Run all legacy tests plus focused forward-performance tests and document the
   controller calibration and concept-model limitations.

## Fast constrained-backward formulation extension

**Architecture:** Existing programmatic UIFigure Explorer with a third
`Constrained` formulation between Backward and Performance. It preserves the
single fixed route-time pass of the backward workflow, but suppresses requested
acceleration using the available battery-current/DC-power, motor torque-speed,
motor power, final-drive force, and road-load capability before integrating an
actual vehicle speed state.

**User-visible behavior:**

- Replace the two-position formulation switch with a three-choice dropdown:
  `Backward`, `Constrained`, and `Performance`.
- Keep Backward as the default and preserve its prescribed-speed results.
- In Constrained mode, use route speed versus time as the driver target while
  sampling grade and auxiliary multiplier at actual travelled distance.
- Run only the original route-time horizon. Report achieved speed, distance,
  completion, speed error, limiting cause, and a stalled/incomplete endpoint;
  do not extend time to force route completion.
- Disable Repeat Route while Constrained is selected because repeated depletion
  is intentionally handled by the detailed Performance formulation.
- Use a short fixed-point motor-loss correction rather than the Performance
  formulation's higher-iteration power inversion, retaining current/torque/force
  saturation while reducing long-route execution time.

**Files:**

- `src/simulate_hybrid_bus_constrained.m`: semantic constrained-mode entry point.
- `src/simulate_hybrid_bus_constrained.m`: two acceleration-suppression passes
  plus a final energy-consistent backward-kernel pass.
- `src/simulate_hybrid_bus.m`: three-formulation dispatcher.
- `HybridBusApp.m`: three-choice formulation control and constrained-mode status.
- `tests/run_all_hybrid_bus_tests.m`: constrained limiting, depletion/stall,
  fixed-horizon, BEV/Hybrid, speed, and legacy-regression scenarios.

**Implementation sequence:**

1. Add the constrained formulation to input validation and dispatch without
   changing Backward defaults.
2. Add fixed-time target-speed handling, actual-distance terrain lookup,
   current/torque/force suppression, and explicit fixed-horizon termination
   around the vectorized backward kernel.
3. Add the three-choice app control, disable incompatible repeat-route behavior,
   and reuse desired/achieved signal and KPI views.
4. Exercise compatible, torque-limited, current/energy-limited, grade-stall,
   Hybrid, BEV, optimizer, and app-launch cases; compare execution time with the
   detailed Performance mode on the same route.
