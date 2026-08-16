# European Commission VECTO mission cycles

The three `.vdri` files in this folder are unmodified declaration-mode mission-cycle inputs from the European Commission's open-source VECTO Sim repository:

- `VECTO_Urban.vdri`
- `VECTO_Suburban.vdri`
- `VECTO_Coach.vdri`

Repository: `https://code.europa.eu/vecto/vecto`  
Commit used: `d16ba783c1d8af0ea68797f5d7ed6cf01877d402`  
Repository path: `VectoCore/VectoCore/Resources/Declaration/MissionCycles/`  
Licence: European Union Public Licence (EUPL) 1.2.

These are official EU representative mission profiles, not GPS recordings of a named German bus line. Germany is within their EU regulatory scope. `convert_vecto_distance_cycle.m` converts their distance-based target speed/grade traces to deterministic 1 Hz time histories suitable for this backward-facing energy model, while preserving the raw distance-domain data in the workbook.

## European long-distance corridors

The `osrm` subfolder contains eight reproducible road-route snapshots requested from the public
Project OSRM route service on 2026-08-14. The road network is OpenStreetMap data:

- Source/attribution: © OpenStreetMap contributors
- Data licence: Open Data Commons Open Database License (ODbL) 1.0
- OSRM API documentation: `https://project-osrm.org/docs/v5.24.0/api/`
- OSM copyright/licence: `https://www.openstreetmap.org/copyright`

Each JSON file preserves the query URL, endpoint coordinates, retrieval time, route distance,
duration, and per-segment distance/speed annotations. `download_europe_long_routes.m` refreshes the
snapshot intentionally; `convert_osrm_coach_route.m` converts it to a bounded coach profile. The
conversion caps speed at 100 km/h, inserts a 45-minute stationary break after each 4.5-hour driving
block, and uses zero grade because the OSRM annotation has no elevation. These are real geographic
road corridors, but their speed traces are routing estimates rather than measured coach telemetry.
