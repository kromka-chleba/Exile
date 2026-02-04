local secenv = core.request_insecure_environment()
local sql

-- the `map.sqlite` table has the following structure
-- CREATE TABLE `blocks` (`x` INTEGER,`y` INTEGER,`z` INTEGER,`data` BLOB NOT NULL,PRIMARY KEY (`x`, `z`, `y`))
-- The code below retrieves data from the table and decodes the blob.
-- What is obtained are node content IDs (core.get_content_id(node_name)) mapped to node names.
-- TODO: content IDs for blocks could get out of date, it is probably good to verify them.

-- load insecure environment

if secenv then
    print("[shepherd_v4_compat] insecure environment loaded.")
    local success, lib = pcall(secenv.require, "lsqlite3")
    if success then
        sql = lib
        assert(sql)
        assert(sql.open)
    else
        core.log("error", "could not find sqlite3. old map update will not function")
        core.log("error", lib)
    end
else
    core.log("error", "[shepherd_v4_compat] failed to load insecure" ..
                 " environment, please add this mod to the trusted mods list.")
    return
end


local wpath = core.get_worldpath()
local filespec = wpath..'/map.sqlite'
local db
if sql then
    db = sql.open(filespec)
end
assert(db)

-- Export functions for use by other files in this mod
local sql_map_reader = {}

local function decode_pos_hash(hash)
        hash = hash + 0x800800800
        local x = bit.band(hash, 0xFFF) - 0x800
        local y = bit.rshift(hash, 12)
        y = bit.band(y, 0xFFF) - 0x800
        local z = bit.rshift(hash, 24)
        z = bit.band(z, 0xFF) - 0x800
        return { x = x, y = y, z = z}
end

-- Decode a mapblock and return node data
function sql_map_reader.decode_mapblock(block_data, block_pos)
    local cursor = 1
    local data = block_data
    
    local function u8()
        local char = string.sub(data, cursor, cursor)
        local out = string.byte(char)
        cursor = cursor + 1
        return out
    end
    
    local function u16()
        return bit.lshift(u8(), 8) + u8()
    end
    
    local function u32()
        return bit.lshift(u16(), 16) + u16()
    end

    local version = u8()

    if version >= 29 then -- Data is now serialized and compressed
        data = core.decompress(string.sub(data, 2, #data), "zstd")
        cursor = 1 -- reset cursor
    end

    local flags = u8()
    local lighting_complete
    if version >= 27 then
        lighting_complete = u16()
    end

    local timestamp, node_id_mapping_version
    if version >= 29 then
        timestamp = u32()
        node_id_mapping_version = u8()
    end

    local num_id_name_mappings = u16()
    local id_name_table = {}

    for i = 1, num_id_name_mappings do
        local id = u16()
        local name_len = u16()
        if name_len > 256 then
            error("Invalid node name length: " .. name_len)
        end
        local name = string.sub(data, cursor, cursor + name_len - 1)
        cursor = cursor + name_len
        id_name_table[tonumber(id)] = name
    end

    -- Content width is always 2 bytes per node
    local content_width = 2
    
    -- Read node data (4096 nodes in a 16x16x16 mapblock)
    local nodes = {}
    for i = 1, 4096 do
        local node_id = u16()
        local node_name = id_name_table[node_id] or "unknown"
        table.insert(nodes, node_name)
    end
    
    return {
        pos = block_pos,
        version = version,
        nodes = nodes,
        id_name_table = id_name_table
    }
end

-- Iterate through all blocks and call a callback for each
function sql_map_reader.iterate_blocks(callback)
    if not db then
        core.log("error", "[shepherd_v4_compat] Database not available")
        return
    end
    
    local count = 0
    local start = os.clock()
    
    for row in db:nrows("SELECT pos,data FROM blocks") do
        local block_pos = decode_pos_hash(row.pos)
        local block_data = sql_map_reader.decode_mapblock(row.data, block_pos)
        callback(block_data)
        count = count + 1
    end
    
    local elapsed = os.clock() - start
    core.log("action", string.format(
        "[shepherd_v4_compat] Processed %d mapblocks in %.2f seconds",
        count, elapsed
    ))
end

return sql_map_reader
