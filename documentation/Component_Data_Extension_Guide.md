# Component Data Extension Guide

The app discovers battery, motor, and genset MATLAB scripts recursively every
time the database is loaded. Restart the app after adding or editing a file.

## Supported identifiers

`ComponentID` must be unique within its catalog, start with a letter, and contain
only letters, digits, dots, underscores, or hyphens. Identifiers are compared
case-insensitively, so `BAT-13` and `bat-13` are duplicates.

Valid examples include `BAT-13`, `Bat_Series_1`, `MOT-HighTorque-A`, and
`Gen_Euro7_300kW`. The filename does not have to match the ID, although matching
names make maintenance easier.

## Add a battery

1. Copy an existing file from `data/batteries`, preferably one with a similar
   voltage and energy class.
2. Rename the file and assign a new `BatteryData.Component.ComponentID`.
3. Update every catalog rating plus `MaxDischargeCurrentMap_A`,
   `MaxChargeCurrentMap_A`, `OpenCircuitVoltageMap_V`, and
   `InternalResistanceMap_Ohm`. Map rows are
   temperature breakpoints and columns are SOE breakpoints. Use schema version
   `4.0.0`; terminal power capability is derived by the model and is not stored
   as a battery rating.
   Set `SOCBreakpoints` to the OCV map's column axis. In the current energy-based
   model, SOC is evaluated using SOE as its concept-level proxy.
4. Set `StorageOrder` to control dropdown position, or remove it to place the
   variant after explicitly ordered records.

The new battery appears in both battery dropdowns and participates in mass,
compatibility, simulation, architecture specifications, and optimization when
`OptimizationEnabled=true`.

## Add a motor

Copy an existing file below `data/motors`, assign a unique
`MotorData.Component.ComponentID`, and update all ratings, voltage class,
reduction-ratio limits, mass, and notes. Use schema `2.0.0` and also update
`TorqueBreakpoints_Nm`, `SpeedBreakpoints_rpm`, and `MotorLossMap_kW`. Map rows
must correspond to increasing absolute speed and columns to increasing absolute
torque; both axes start at zero and the zero-speed/zero-torque loss is zero. The
map is per motor in kW. The new motor is automatically available to manual
selection and optimization.

## Add a genset assembly

Copy one existing file below `data/gensets`. Assign unique IDs independently to:

- `GensetData.Genset.ComponentID`
- `GensetData.Engine.ComponentID`
- `GensetData.Generator.ComponentID`

The IDs do not need related prefixes or suffixes. The loader treats the genset,
engine, generator, engine fuel map, and generator efficiency map in that file as
one assembly and builds an explicit assembly-link table. Update both maps and all
ratings consistently.

## Preservation and validation

`create_default_database` rewrites the known built-in filenames but does not
delete additional `.m` files. Add-ons therefore survive normal database
regeneration. The loader searches subfolders too, so a `custom` subfolder may be
used for user data.

Run this validation after adding a component:

```matlab
DB = load_hybrid_bus_database;
V = validate_hybrid_bus_database(DB);
assert(V.IsValid, join(V.Errors, newline));
```

Validation rejects missing fields, invalid maps, unsafe IDs, duplicate IDs,
inconsistent genset assembly links, and physically invalid catalog limits.
