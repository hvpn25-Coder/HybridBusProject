# System Architecture

## Power domains

```text
TRACTION:  active battery <-> traction DC bus <-> inverters/motors <-> reductions <-> wheels
                                    |-> auxiliary loads

CHARGING:  diesel -> engine -> generator -> fixed-point charger -> standby battery
```

The two domains share battery energy states and supervisory commands, but the genset has no electrical path to the traction DC bus. It cannot propel the vehicle, supply auxiliaries, or reduce active-battery demand.

## Control principles

1. Exactly one battery is active for traction; the other is standby.
2. The active battery is allowed to discharge to 30% SOE.
3. At or below 30%, roles swap immediately if the standby pack is above 30%.
4. If both packs are low, the current active pack remains connected while the genset charges standby, preventing role chatter.
5. When on, the genset produces one constant command: `OptimumPower_kW`.
6. The genset keeps charging the standby pack until it reaches its upper SOE limit or becomes the active pack, subject to minimum on/off times and battery acceptance limits.

## Simulink top level

1. `Route_and_Environment` - time-aligned speed, grade, and auxiliary multiplier.
2. `Vehicle_Longitudinal_Dynamics` - filtered acceleration and first-principles wheel power.
3. `Rear_Hub_Motor_Drive` - two motors, fixed reduction, directional efficiencies, speed and power limits.
4. `Auxiliary_Loads` - stationary-capable ambient and route-dependent load.
5. `Supervisory_Energy_Management` - stateful 30% role selection, isolated standby charging, and regeneration mode.
6. `Battery_Pack_1` and `Battery_Pack_2` - independent energy states, efficiency, power and SOE limits.
7. `Engine_Genset` - constant optimum electrical output when enabled and fuel-rate calculation.
8. `Energy_and_Cost_Accounting` - combined-boundary residual and cumulative cost.
9. `Output_Logging` - stable workspace signal names.

The detailed MATLAB kernel and the SLX use the same parameter source and sign convention. Both implement the isolated standby-charging architecture.

## Solver and route adaptation

Fixed-step discrete, default 1 s sample time. Route inputs are linearly resampled for speed, grade, and auxiliary multiplier; stop flags use previous-value interpolation. There are no continuous states or algebraic loops.

`convert_vecto_distance_cycle.m` retains each official distance-domain target trace and derives a repeatable 1 Hz time history using 1.0 m/s^2 acceleration and 1.3 m/s^2 braking bounds. `convert_osrm_coach_route.m` adapts OSM/OSRM road segments at 10 s resolution, caps coach speed at 100 km/h, and adds EU-style 45-minute driver breaks after each 4.5-hour driving block. Long-route grade remains zero because OSRM does not provide elevation.
