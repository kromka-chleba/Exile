# Shepherd Mapblock Migration Notes

This document describes the migration from the mapchunk-based shepherd API to the mapblock-based API.

## Changes Made

### 1. API Function Renames
- `ms.chunk_side()` → `ms.block_side()` 
  - Returns the side length of a mapblock in nodes (16)
  - Used throughout complex_workers.lua for array indexing

- `ms.mapchunk_hash()` → `ms.mapblock_hash()`
  - Computes a hash for a mapblock position
  - Now uses Luanti's standard `core.hash_node_position()`
  - Updated in complex_workers.lua, volcanoes.lua, and spawnex/init.lua

### 2. API Signature Changes
- `ms.label_store.new(blockpos)` - Takes position vector, not hash
- `ms.mapgen_watchdog.new(blockpos)` - Takes position vector, not hash
- Use `ms.units.mapblock_coords(node_pos)` to convert node position to blockpos

### 3. Terminology Changes
The system has migrated from "mapchunk" terminology to "mapblock":
- **Mapblock**: 16x16x16 nodes (what the system now processes)
- **Mapchunk**: 5x5x5 mapblocks = 80x80x80 nodes (old terminology, no longer used)

## Worker Edge Handling

### Current Approach
Workers in `complex_workers.lua` (evaporator, soak_out_move_down, gravity_soak_in) currently:
1. Skip processing nodes at block boundaries (x/y/z == 0 or 15)
2. Store "orphan" positions for boundary nodes
3. Process orphans later using ABM-style callbacks in afterworker

Example from complex_workers.lua:
```lua
-- Lines 73-75, 344-346
if not (x == 0 or x == block_side - 1 or
        z == 0 or z == block_side - 1 or
        y == 0 or y == block_side - 1) then
    -- Process node
else
    -- Store as orphan
    table.insert(nn.moisture_orphans[hash], vector.add(pos_min, node_pos))
end
```

### Optional Refactoring: Block Neighborhood Wrapper

The new shepherd API provides a `block_neighborhood` wrapper that allows workers to:
- Read and write nodes in adjacent mapblocks
- Eliminate orphan tracking
- Process boundary nodes directly within the worker

See `/mods/mapchunk_shepherd/example_neighbor_worker.lua` for a complete example.

#### Benefits
- More efficient (no ABM callbacks needed)
- Cleaner code (no orphan tracking)
- True cross-block operations in a single pass

#### Refactoring Steps (for future work)

1. **Wrap the worker function:**
```lua
local bn = ms.block_neighborhood

local function moisture_worker(pos_min, pos_max, vm_data, chance, neighborhood)
    -- Can now access adjacent blocks via neighborhood:read_node() / write_node()
    -- neighborhood:get_adjacent_positions() for 6-connectivity
    return labels_to_add, labels_to_remove, light_changed, param2_changed
end

local wrapped = bn.wrap_worker_function(moisture_worker, true)
```

2. **Update worker registration:**
```lua
ms.worker.new({
    name = "moisture_spread_worker",
    fun = wrapped,  -- Use wrapped function
    -- ... other params
}):register()
```

3. **Remove orphan handling:**
- Remove `nn.moisture_orphans` and `nn.water_orphans` tracking
- Remove `handle_sediment_orphans` and `handle_water_orphans` callbacks
- Remove boundary exclusion checks

#### Example Worker Patterns

**Reading from neighbor:**
```lua
local neighbor_pos = vector.add(world_pos, vector.new(1, 0, 0))
local neighbor_node = neighborhood:read_node(neighbor_pos)
```

**Writing to neighbor:**
```lua
if neighbor_node == air_id then
    neighborhood:write_node(neighbor_pos, water_id)
end
```

**Getting adjacent positions:**
```lua
local adjacent = neighborhood:get_adjacent_positions(world_pos)
for _, adj_pos in ipairs(adjacent) do
    local node = neighborhood:read_node(adj_pos)
    -- Process
end
```

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
