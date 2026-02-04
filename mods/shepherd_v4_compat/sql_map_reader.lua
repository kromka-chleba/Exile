local secenv = core.request_insecure_environment()
local sql

-- the `map.sqlite` table has the following structure
-- CREATE TABLE `blocks` (`x` INTEGER,`y` INTEGER,`z` INTEGER,`data` BLOB NOT NULL,PRIMARY KEY (`x`, `z`, `y`))
-- The code below retrieves data from the table and decodes the blob.
-- What is obtained are node content IDs (core.get_content_id(node_name)) mapped to node names.
-- TODO: content IDs for blocks could get out of date, it is probably good to verify them.

-- load insecure environment

if secenv then
    print("[rangefind] insecure environment loaded.")
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
    core.log("error", "[mapmigrate] failed to load insecure" ..
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

local function decode_pos_hash(hash)
        hash = hash + 0x800800800
        local x = bit.band(hash, 0xFFF) - 0x800
        local y = bit.rshift(hash, 12)
        y = bit.band(y, 0xFFF) - 0x800
        local z = bit.rshift(hash, 24)
        z = bit.band(z, 0xFF) - 0x800
        return { x = x, y = y, z = z}
end

local start = os.clock()

for a in db:nrows("SELECT pos,data FROM blocks") do
    local cursor = 1
    local data = a.data
    local function u8()
        local char = string.sub(data, cursor, cursor+1)
        local out = string.byte(char)

        cursor = cursor + 1
        return out
    end
    local function u16()
        return  bit.lshift( u8(), 8) + u8()
    end
    local function u32()
        return  bit.lshift( u16(), 16) + u16()
    end

    --print() -- New line
    local pos = decode_pos_hash(a.pos)
    --print("Position: ",core.pos_to_string(pos))

    local version = u8()
    --print("Version: ",version)

    if version >= 29 then -- Data is now serialized and compressed
        data = core.decompress(string.sub(data, 2, #data), "zstd")
        cursor = 1 -- reset cursor
        --print(dump(data), " Deserialized: ",core.deserialize(data))
    end

    local flags = u8()
    --print( " Flags: ",flags)
    local lighting_complete
    if version >= 27 then  lighting_complete = u16()    end
    --print(" Lighting complete: ",lighting_complete)


    local timestamp, node_id_mapping_version
    if version >= 29 then
        timestamp = u32()
        --print("Timestamp: ",timestamp," - ",bit.tohex(timestamp))

        node_id_mapping_version = u8()
        --print(" Node ID mapping version:",node_id_mapping_version)
    end

    local num_id_name_mappings = u16()
    local id_name_table = {}

    --print("Number of ID mappings: ",num_id_name_mappings)

    for i = 1, num_id_name_mappings do
        local id = u16()
        local name_len = u16()
        if name_len > 256 then error() end
        name = string.sub(data, cursor, cursor + name_len - 1)
        cursor = cursor + name_len

        id_name_table[tonumber(id)] = name
        id_name_table[name] = tonumber(id)

    end
    --print("Node IDs: ---------------")
    --for key, value in pairs(id_name_table) do print(key, " = ", value) end
end
local stop = os.clock()
local bench = stop - start
print("Total time taken: ",bench)
