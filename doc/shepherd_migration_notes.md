# Shepherd Mapblock Migration Notes

This document describes the migration from the mapchunk-based shepherd API to the mapblock-based API.

## Recent Updates

### Season-Aware Mapgen (February 2026)
New chunks now generate with the correct seasonal state instead of always appearing in summer:

**IPC Communication**
- Main environment sends current season to mapgen via `core.ipc_set("exile:current_season", season_name)`
- Mapgen environment reads season via `core.ipc_get("exile:current_season")`
- Season updates automatically when game time progresses

**Seasonal Node Replacement**
- **Soils**: Winter soils generate in winter seasons, spring/summer soils in other seasons
- **Plants**: All 8 seasonal plant variants supported (spring_early, spring_late, summer_early, summer_late, fall_early, fall_late, winter_early, winter_late)
- **Performance**: Only processes when season differs from default summer state

**Implementation Files**
- `seasons.lua`: Updates IPC when season changes
- `seasonal_mapgen.lua`: Runs in mapgen environment, replaces nodes based on season
- Registered via `minetest.register_mapgen_script()`

### Surface Finder API (February 2026)
Added efficient surface detection using heightmap during mapgen:
- **Surface finder**: Uses `core.get_mapgen_object("heightmap")` to detect surface blocks
- **Margin support**: Configurable margin to include blocks above/below exact surface
- **Standard tags**: `surface`, `underground`, `aboveground` (provided by shepherd's common_tags.lua)
- **Usage**: Replaces node-based detection for seasonal soil and moisture spread

**Note:** The surface-related tags are pre-registered in the shepherd mod's `common_tags.lua` file. Exile should NOT re-register these tags to avoid duplicate registration errors.

**Configuration:**
```lua
ms.create_surface_finder({
    margin = 1  -- Include 1 block above and below exact surface
})
```

**Benefits:**
- ✅ Runs during mapgen (more efficient than LBMs)
- ✅ Uses heightmap data (no node scanning needed)
- ✅ Consistent detection across all biomes
- ✅ Reduces worker overhead by pre-labeling surface blocks

## Changes Made

### 1. API Function Renames
- `ms.chunk_side()` → `ms.block_side()` 
  - Returns the side length of a mapblock in nodes (16)
  - Used throughout complex_workers.lua for array indexing

- `ms.mapchunk_hash()` → `ms.mapblock_hash()`
  - Computes a hash for a mapblock position
  - Now uses Minetest/Luanti's standard `core.hash_node_position()`
  - Updated in complex_workers.lua, volcanoes.lua, and spawnex/init.lua

### 2. API Signature Changes
- `ms.label_store.new(blockpos)` - Takes position vector, not hash
- `ms.mapgen_watchdog.new(blockpos)` - Takes position vector, not hash
- Use `ms.units.mapblock_coords(node_pos)` to convert node position to blockpos

### 3. Terminology Changes
The system has migrated from "mapchunk" terminology to "mapblock":
- **Mapblock**: 16x16x16 nodes (what the system now processes)
- **Mapchunk**: 5x5x5 mapblocks = 80x80x80 nodes (old terminology, no longer used)

## Worker Edge Handling - COMPLETED ✅

### Previous Approach (Removed)
Workers previously:
1. Skipped processing nodes at block boundaries (x/y/z == 0 or 15)
2. Stored "orphan" positions for boundary nodes
3. Processed orphans later using ABM-style callbacks in afterworker

### Current Approach (Implemented)
Workers now use the `block_neighborhood` API to:
- Read and write nodes in adjacent mapblocks
- Process boundary nodes directly within the worker
- Eliminate orphan tracking and afterworker callbacks

### Implementation Details

All three complex workers have been refactored:

1. **create_evaporator**
   - Uses `neighborhood:read_node()` to check air neighbors
   - Uses `neighborhood:get_adjacent_positions()` for 6-connectivity
   - Processes all nodes including boundaries

2. **create_soak_out_move_down**
   - Refactored moisture spread to use neighborhood API
   - Checks wet/dry neighbors across block boundaries
   - Handles air positions for soak-out across edges

3. **create_gravity_soak_in**
   - Water gravity uses neighborhood API
   - Checks below and sideways positions across boundaries
   - Implements downward bias by checking below positions twice

### Benefits Achieved
- ✅ More efficient (no ABM callbacks needed)
- ✅ Cleaner code (no orphan tracking)
- ✅ True cross-block operations in a single pass
- ✅ Proper moisture spread across boundaries
- ✅ Correct water gravity at block edges
- ✅ Working evaporation at boundaries

### Code Removed
- `is_at_block_boundary()` helper function
- `nn.moisture_orphans` and `nn.water_orphans` tables
- `handle_sediment_orphans()` and `handle_water_orphans()` callbacks
- All boundary exclusion checks

## Compatibility Notes

- The `labels_to_position()` API remains unchanged and works correctly
- Mapgen biome and decoration finders work the same way
- Worker function signatures are backward compatible (neighborhood param is optional)

## Testing Recommendations

1. Test moisture spread mechanics across block boundaries
2. Verify water gravity works correctly at edges
3. Check evaporation behavior near block boundaries
4. Confirm volcano labeling during mapgen
5. Test spawn point selection with label checks

## References

- Shepherd README: `/mods/mapchunk_shepherd/README.md`
- API Documentation: `/mods/mapchunk_shepherd/shepherd_API.md`
- Example worker: `/mods/mapchunk_shepherd/example_neighbor_worker.lua`
- Block neighborhood module: `/mods/mapchunk_shepherd/block_neighborhood.lua`
