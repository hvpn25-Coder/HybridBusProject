# Validation Data and Extension Plan

This plan defines the evidence needed to advance the project beyond concept verification. Missing data must remain a visible credibility gate; synthetic replacements must not be presented as validation.

## 1. Supplier calibration package

| Component | Required data | Minimum metadata | Intended use |
|---|---|---|---|
| Battery packs | OCV versus SOE and temperature, resistance, usable energy, charge/discharge current limits, efficiency, thermal limits | temperature, age, sample rate, pack configuration, test procedure | voltage/current and thermal calibration |
| Hub motors and inverters | torque-speed envelope, motoring/regeneration efficiency maps, DC-voltage range, thermal derating | coolant condition, DC voltage, winding temperature, test standard | power-limit and loss calibration |
| Engine-generator | BSFC map, generator efficiency map, optimum operating point, start fuel, warm-up behavior | fuel properties, ambient condition, measurement uncertainty | fuel and charging calibration |
| Reduction gears | directional efficiency and thermal rating | oil temperature, speed and torque range | driveline loss calibration |
| Auxiliary loads | HVAC, pumps, steering, air system, hotel load profiles | ambient temperature, occupancy, operating mode | route-dependent auxiliary calibration |

## 2. Vehicle validation dataset

Collect synchronized CAN/GPS or dynamometer channels:

- timestamp, latitude, longitude, altitude, vehicle speed, and road grade;
- wheel or axle torque and speed;
- Battery 1 and Battery 2 voltage, current, SOE, temperature, contactor state, and active/standby role;
- motor and inverter torque, speed, DC power, and temperature;
- genset command, electrical output, engine speed, fuel flow, and cumulative fuel;
- auxiliary DC power and HVAC state;
- vehicle mass, passengers, ambient temperature, wind, tyre condition, and route identifier.

Minimum study coverage should include urban, suburban, coach, hot-HVAC, cold-HVAC, high-mass, positive-grade, regenerative-braking, battery-role-swap, and genset-charging events.

## 3. Proposed validation metrics

Acceptance limits must be approved before examining validation results. Initial engineering proposals are:

| Metric | Proposed reporting |
|---|---|
| Route distance and speed | absolute and RMS error; time alignment documented |
| Wheel and motor energy | route-integrated relative error plus peak-power error |
| Battery energy and terminal SOE | per-pack energy error and final-SOE absolute error |
| Genset energy and fuel | electrical-energy and cumulative-fuel relative error |
| Auxiliary energy | route-integrated relative error by operating condition |
| Mode transitions | event-time difference and missed/extra transition count |
| Energy conservation | integrated absolute residual |

## 4. Forward-facing feasibility extension

Add a driver and speed controller, vehicle longitudinal state, traction/braking saturation, gradeability, and stopping-distance checks. Compare achieved speed with the prescribed route. A backward-facing energy result is feasible only when the forward-facing vehicle follows the route within an approved speed-error envelope without violating motor, battery, tyre, or braking limits.

## 5. Thermal, electrical, and ageing extension

Add battery voltage/current, cell or pack temperature, motor/inverter temperature, genset warm-up, coolant or lumped thermal states, and capacity/resistance ageing. Report continuous and transient margin to every thermal and electrical limit. Do not infer lifetime from energy throughput alone.

## 6. Safety and fault-analysis extension

Perform FMEA or STPA before fault injection. Minimum faults include SOE sensor bias/stuck values, battery contactor failure, failed role swap, inverter loss, motor derating, genset charger over/under-power, load-bank unavailable, auxiliary overload, cooling loss, isolation fault, and communication timeout. Define detection, safe state, degraded operation, driver warning, and verification test for each fault.

## 7. Release rule

A gate moves to PASS only when its evidence file, acceptance criteria, results, reviewer, and model/database version are recorded. “Not available,” “not implemented,” and “failed” are valid engineering outcomes and must remain visible to management.
