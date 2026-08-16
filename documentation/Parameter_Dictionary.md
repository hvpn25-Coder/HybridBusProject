# Parameter Dictionary

| Area | Principal parameters | Source |
|---|---|---|
| Vehicle | mass, gravity, Cd, frontal area, Crr | Mass/Tyre/Vehicle sheets |
| Route | time, speed, grade, dwell, auxiliary multiplier | Route sheets |
| Hub drive | wheel radius, ratio, directional drive efficiency, torque/power/speed limits | Tyre/Final Drive/Motor sheets |
| Battery | usable energy, initial/min/max SOE, charge/discharge efficiency and limits, regen acceptance | Battery sheet + Dashboard |
| Genset | optimum/max power, minimum times, BSFC, generator efficiency, fuel density | Genset/maps |
| Supervisor | fixed 30% role threshold, standby upper-SOE target, regeneration redirect | Architecture rule + Control sheet |
| Cost/range | fuel tank, fuel/electric prices, grid efficiency, terminal method/tolerance | Dashboard/Vehicle/Price/Optimization sheets |

The loader resolves all component IDs to scalar parameter structures. `assign_hybrid_bus_model_workspace` publishes only stable, unit-suffixed values required by the SLX.
