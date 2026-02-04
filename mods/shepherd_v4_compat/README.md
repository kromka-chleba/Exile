# Shepherd v4 Compatibility Module

This mod provides compatibility for worlds upgrading from older versions of Exile (v0.3 and early v0.4-beta) where the mapchunk_shepherd internal database format changed.

## Purpose

The mapchunk_shepherd mod assigns labels to mapchunks (16x16x16 blocks) during mapgen based on:
- Biome information
- Decoration placement
- Node content

When the database format changed, this labeling information was lost for existing mapchunks. This mod reads the historical node data from the `map.sqlite` database and re-assigns shepherd labels based on the nodes present in each mapchunk.

## How It Works

1. **SQL Map Reader** (`sql_map_reader.lua`): Reads and decodes mapblock data from the `map.sqlite` database, including:
   - Node ID to name mappings
   - Individual node content for all 4096 nodes per mapblock
   - Block position information

2. **Label Assignment** (`shepherd_labels.lua`): 
   - Maps specific nodes to shepherd labels (e.g., `nodes_nature:salt_water_source` → `ocean` label)
   - Checks node groups (e.g., `group:wet_sediment` → `moisture_spread` label)
   - Detects seasonal soil patterns (e.g., nodes with `_spring` → `spring_soil` and `seasonal_plants` labels)
   - Assigns appropriate labels to mapchunks using the `ms.labels_to_position()` API

3. **Migration Execution**: Runs automatically on mod load, processing all mapblocks in the database.

## Node to Label Mappings

The following mappings are implemented based on the `shepherd_v3_compat` patterns:

- **Ocean**: `nodes_nature:salt_water_source` → `ocean`
- **Freezing**: `nodes_nature:ice`, `nodes_nature:sea_ice` → `last_freezed`
- **Snow**: `nodes_nature:snow`, `nodes_nature:snow_block` → `last_snow`
- **Water**: `nodes_nature:freshwater_source` → `water_gravity`
- **Moisture**: `group:wet_sediment` → `moisture_spread`
- **Leaves**: `group:drops_leaves` → `leaves`
- **Leaf Markers**: `group:leaf_marker` → `leaves_dropped`
- **Spring Soil**: Nodes matching `*_spring*` pattern → `spring_soil`, `seasonal_plants`
- **Winter Soil**: Nodes matching `*_winter*` pattern → `winter_soil`, `seasonal_plants`

## Requirements

- This mod requires secure environment access to use the `lsqlite3` library
- Add `shepherd_v4_compat` to your trusted mods list in `minetest.conf`:
  ```
  secure.trusted_mods = shepherd_v4_compat
  ```

## Performance

The migration runs once on server start and processes all existing mapblocks. Processing time depends on world size:
- Progress is logged every 1000 mapblocks
- Total processing time is reported when complete
