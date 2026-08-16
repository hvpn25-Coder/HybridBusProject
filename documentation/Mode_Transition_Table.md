# Supervisory Mode-Transition Table

The 30% SOE role threshold is an architecture rule and is not tunable by the selected calibration.

| Priority | Current condition | Action / next mode |
|---:|---|---|
| 1 | Active SOE <= 30% and standby SOE > 30% | Exchange active and standby roles immediately |
| 2 | Both packs <= 30% | Keep the present active pack to avoid chatter; charge the standby pack until it is ready |
| 3 | Standby SOE <= 30% after minimum genset off-time | Start genset at constant `OptimumPower_kW`; apply start-fuel penalty |
| 4 | Genset on and standby below its upper SOE limit | Route genset power only to standby battery (Modes 3/4) |
| 5 | Genset on and standby reaches its upper SOE limit after minimum on-time | Stop genset |
| 6 | Positive motor-plus-auxiliary demand | Sole active battery supplies the entire traction DC-bus demand (Modes 1/2) |
| 7 | Regenerative DC power | Charge an eligible battery; genset charging remains a separate path (Mode 6) |
| 8 | Active-pack power/energy capability insufficient | Clamp source, log unmet demand, enter protection indication (Mode 7) |

Mode numbers: 1 B1 active; 2 B2 active; 3 B1 active/B2 charged by genset; 4 B2 active/B1 charged by genset; 6 regenerative allocation; 7 energy-limit protection. Mode 5 is unused in the revised architecture because the genset never supports traction.
