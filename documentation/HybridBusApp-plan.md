# Implementation Plan: HybridBusApp

**Architecture:** UIFigure application

**Serialization:** Programmatic App Designer-compatible MATLAB class (`HybridBusApp.m`). This is the documented R2025a fallback requested in the specification; it uses only public `uifigure` components and opens directly from MATLAB.

**Layout:** Explorer — a stable left control panel for database/configuration inputs and a responsive main area with KPI summary, plots, and ranked configurations.

## Structure

- Slightly widened left control grid: database browser; a titled `Mission Inputs` panel that keeps Route, Total vehicle mass, and Auxiliary together; component selectors; price/SOE inputs; manual/optimization mode controls; run/cancel/export actions; and progress status.
- Add a `Repeat route until depleted` checkbox. Off preserves the single-cycle study; on repeats the selected speed/grade/auxiliary mission continuously and terminates when the fuel tank is empty and neither battery can provide usable traction energy.
- Main tab group in workflow order: Powertrain Architecture, Route Map, KPIs, Simulation Analysis, Model Credibility, Optimization Ranking, Signals, and Detailed Plot.
- KPI tab as a management dashboard: a concise mission/status header followed by twelve icon-led KPI cards in four columns, with large values, explicit units, and semantic accent colors for executive, energy, battery, and engineering-health results.
- Simulation Analysis tab: a concise run interpretation header, energy-flow comparison chart, active-battery duty-share chart, and an engineering assessment table covering mission completion, battery limits, regeneration utilization, genset duty, unmet demand, and conservation error.
- Model Credibility tab: release-gate status, explicit evidence and decisions, powertrain concept screening, and a sensitivity tornado-style chart. Failed, unavailable, and not-implemented evidence remains visible instead of being converted into a cosmetic pass.
- Core computation remains in ordinary MATLAB functions outside UI callbacks so batch and test workflows use identical logic.

## Key behaviors

- Load and validate the default or browsed workbook.
- Keep Route, Total vehicle mass, and Auxiliary together in one nested, responsive `Mission Inputs` panel without changing their data bindings or callbacks.
- Present initial battery SOE inputs as percentages with `%` units while converting to normalized SOE only at the simulation boundary.
- Label operating prices explicitly as `EUR/L` and `EUR/kWh`.
- Display human-readable route names backed by official European Commission VECTO Urban, Suburban, and Coach mission-cycle IDs.
- Present 12 explicit total-vehicle-mass variants spanning 19,000 kg through 60,000 kg, with kg shown in the selector; use the selected total directly in longitudinal dynamics.
- Add sourced, geographic European coach corridors in the 600-1,000 km range, with human-readable endpoints and stable route IDs in the existing selector.
- Run a selected configuration and display speed, power, genset, fuel, and cost histories; present Battery 1 and Battery 2 SOE on a 0-100 percentage scale with percent-formatted y-axis ticks.
- Scale the Signals and Detailed Plot time axes for human interpretation: use minutes for missions shorter than two hours and hours for missions of two hours or longer. Keep all simulation calculations and fuel integration in seconds, and apply the selected display unit consistently to every plotted signal.
- Add synchronized slider-style `Time / Distance` switches to the Signals and Detailed Plot tabs. Time mode retains adaptive minutes/hours; Distance mode uses cumulative vehicle distance in kilometres. Switching either tab updates both tabs so comparisons always use one common horizontal coordinate.
- Replace the raw one-row KPI table with a scan-friendly dashboard while preserving the existing summary calculations. Populate route distance, operating cost, fuel use, source-energy intensity, grid energy, regeneration, auxiliary energy, fuel consumed, final battery SOEs, unmet energy, and energy-balance error; show feasibility as an immediate status badge.
- Provide a `Detailed Plot` tab with a top-row dropdown and one responsive axes. The dropdown selects acceleration, speed, distance, wheel/motor/reduction-gear torque, wheel/motor/battery power, or engine/generator power and redraws immediately from the latest result.
- Add a `Route Map` tab with a top slider-style `2D / 3D` switch, a preserved geographic 2D axes, a latitude-longitude-elevation 3D axes, and a route-information table. Selecting a geographic corridor redraws both views from the same ordered samples; VECTO regulatory cycles explicitly report that no unique real-world geometry exists instead of displaying invented coordinates.
- Extend the workbook `Route_Geometry` sheet with terrain elevation in metres and explicit elevation provenance. Use cached Copernicus DEM GLO-90 samples obtained through Open-Meteo, interpolate only between sourced points for display continuity, and retain OpenStreetMap/OSRM geometry attribution separately. The elevation view is a visualization input and does not silently replace the simulation-grade channel.
- In 3D mode, color the route by elevation, label longitude, latitude, and elevation units, preserve start/destination markers, and show minimum, maximum, and total elevation gain in the information table. Switching back to 2D restores the existing streets basemap without recomputing the route.
- Reveal a second `Elevation / Slope` slider only while Route Map is in 3D mode. Elevation mode uses metres for both vertical position and color; Slope mode derives road grade as 100 times elevation change divided by path-distance change and uses percent for vertical position and color. Keep start/destination markers and report the calculation basis in the route-information table.
- Render every slider-style switch through one reusable labeled-switch treatment: the selected side is blue and semibold, while the unselected side is gray. Refresh this state after every toggle, including synchronized Time/Distance switches.
- Derive display-only torque channels from the logged wheel force, delivered wheel power, tyre radius, final-drive ratio, and directional efficiencies; do not alter the simulation state or controller calculations.
- Provide a `Powertrain Architecture` tab with native vector component icons and three aligned visual lanes: supervisory control at the top, the isolated genset/standby-charging chain in the middle, and the active-battery traction chain below it.
- Make every component block in the Powertrain Architecture tab clickable. Clicking opens a non-modal, consistently formatted specification window populated from the app's current component selections and database catalog. For functional blocks without a hardware catalog entry, display the implemented control/power-flow rule and clearly identify ratings that are not parameterized rather than inventing values. Include a visible click instruction and preserve the uncluttered power-flow diagram.
- Add a blue/gray `Hybrid / BEV` selector at the top of Powertrain Architecture. Hybrid remains the default and preserves the isolated standby-charging architecture. BEV removes the genset/fuel path, connects Battery 1 alone or both voltage-compatible batteries to the traction bus, and redraws the diagram and explanatory note immediately.
- Add a numeric `Battery set multiplier` configuration input. Hybrid mode accepts positive integers: one set is one active Battery-1 pack plus one standby Battery-2 pack, and each additional set duplicates both role banks. BEV mode accepts positive half-set increments: 0.5/1.0/1.5/2.0 sets connect 1/2/3/4 packs. Odd BEV totals assign the additional pack to the Battery-1 selection. Default is 1.0 set.
- Remove the BEV `Use both batteries` checkbox. In BEV mode, initialize all connected packs to the same 85% SOE, keep the two displayed SOE inputs synchronized, disable the genset selector, and derive connected-pack count solely from the set multiplier.
- Extend simulation input, optimization overrides, component mass, available battery energy, charge/discharge/regen power limits, range calculations, summary metadata, component specification dialogs, and Simulink workspace parameters with `BatterySetMultiplier` and deterministic Battery-1/Battery-2 pack counts. Parallel BEV banks share discharge and regenerative charge in proportion to instantaneous bank capability. Hybrid role switching continues between equal-sized active and standby banks, while the isolated genset remains at its single best-efficiency power point.
- Add an editable `HybridBus_BEVModel.slx` using the same route, vehicle, motor, battery, auxiliary, final-drive, and price parameters as the common database. Its top-level interfaces shall expose the two battery paths, parallel BEV energy manager, traction demand, regenerative allocation, and logging without an engine-genset subsystem.
- Route regenerative power with an explicit first-priority order: satisfy DC auxiliary loads, charge only the active battery within its instantaneous power/SOE limits, then dissipate all remaining regenerative power in a resistor load bank. Expose the three allocations in simulation results and energy KPIs.
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

## Implementation sequence

1. Build and validate the reusable data/simulation functions.
2. Create the explorer layout with `uigridlayout` only.
3. Bind callbacks to the reusable functions.
4. Add standard plots and the dropdown-driven detailed-plot tab, then ranked table, progress/cancel, and export.
5. Launch the app in R2025a and execute a manual run.
6. Render the architecture tab at the normal 1400 x 820 app size and visually verify that blocks, labels, and interconnections do not overlap.
7. Exercise auxiliary-first, active-battery-second, and full-battery load-bank cases and verify DC energy conservation.
8. Verify the Route Map switch in both positions, confirm all geographic routes have finite elevations with unchanged coordinate ordering, and visually inspect representative urban and long-distance 3D routes.
9. Click every Powertrain Architecture block, confirm that each opens one readable specification window, and verify that Battery 1, Battery 2, motor, genset, mass, and auxiliary specifications follow the current configuration selections.
10. Verify 2D hides the Elevation/Slope control, 3D reveals it, both 3D quantities redraw with correct units, all route-slope samples are finite, and every switch uses blue for its selected label and gray for its unselected label.
11. Verify Hybrid rejects fractional multipliers, BEV accepts only half-set increments, 0.5-set BEV leaves Battery 2 disconnected, 1.5-set BEV represents two Battery-1 packs plus one Battery-2 pack, energy and power capability scale with pack count, Hybrid/BEV switching preserves the appropriate SOE defaults, BEV fuel use is exactly zero, regeneration conserves energy, and both Simulink models remain structurally healthy.
