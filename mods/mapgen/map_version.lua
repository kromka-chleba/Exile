local wp = minetest.get_worldpath()

local map_is_new = io.open(wp.."/env_meta.txt", "r") == nil
local old_v4_map = core.get_mapgen_setting("use_exile_v4_biomes")
local current_version = core.get_mapgen_setting("exile_map_version")

if current_version == nil then
    if map_is_new then
        current_version = "v4beta" --"v4"
    elseif old_v4_map == "true" then
        current_version = "v4beta"
    elseif old_v4_map == "false" or old_v4_map == nil then
        current_version = "v3"
    end
    core.log("action","--------------------------------------------------")
    core.log("action","MAPGEN: Exile_map_version detected as "..current_version)
    core.log("action","--------------------------------------------------")
    if current_version == nil then error("Could not determine map version") end
    core.set_mapgen_setting("exile_map_version", current_version)
end

return current_version

