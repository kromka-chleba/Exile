minimal = minimal

minimal.mtversion = {}

local version = minetest.get_version()
local tabstr = string.split(version.string,".")
local major = tonumber(tabstr[1])
local minor = tonumber(tabstr[2])
local dev = tostring(string.match(tabstr[3], "-dev") ~= nil)
-- '%d[%d]*' extracts the first string of consecutive numeric chars
local patch = tonumber(string.match(tabstr[3], '%d[%d]*'))
minetest.log("action", "Running on version: "..version.project.." "..
             major.."."..minor.."."..patch.." Dev version: "..dev)
minimal.mtversion = { project = version.project, major = major,
                      minor = minor, patch = patch, dev = dev }

function minimal.get_daylight(pos, tod)
    if minetest.get_natural_light then
        return minetest.get_natural_light(pos, tod)
    else
        return minetest.get_node_light(pos,tod)
    end
end

minimal.compat_alpha = {}
if minetest.has_feature("use_texture_alpha_string_modes") then
    minimal.compat_alpha = {
        ["blend"] = "blend",
        ["opaque"] = "opaque",
        ["clip"] = "clip",
    }
else
    minimal.compat_alpha = {
        ["blend"] = true,
        ["opaque"] = false,
        ["clip"] = true, -- may be false for some draw types?
    }
end
minimal.hud_type = "hud_elem_type"
if minetest.has_feature("hud_def_type_field") == true then
    minimal.hud_type = "type"
end
