EXILE = EXILE

EXILE.mtversion = {}

local version = core.get_version()
local tabstr = string.split(version.string,".")
local major = tonumber(tabstr[1])
local minor = tonumber(tabstr[2])
local dev = tostring(string.match(tabstr[3], "-dev") ~= nil)
-- '%d[%d]*' extracts the first string of consecutive numeric chars
local patch = tonumber(string.match(tabstr[3], '%d[%d]*'))
core.log("action", "Running on version: "..version.project.." "..
             major.."."..minor.."."..patch.." Dev version: "..dev)
EXILE.mtversion = { project = version.project, major = major,
                      minor = minor, patch = patch, dev = dev }

function EXILE.get_daylight(pos, tod)
    if core.get_natural_light then
        return core.get_natural_light(pos, tod)
    else
        return core.get_node_light(pos,tod)
    end
end

EXILE.compat_alpha = {}
if core.has_feature("use_texture_alpha_string_modes") then
    EXILE.compat_alpha = {
        ["blend"] = "blend",
        ["opaque"] = "opaque",
        ["clip"] = "clip",
    }
else
    EXILE.compat_alpha = {
        ["blend"] = true,
        ["opaque"] = false,
        ["clip"] = true, -- may be false for some draw types?
    }
end
EXILE.hud_type = "hud_elem_type"
if core.has_feature("hud_def_type_field") == true then
    EXILE.hud_type = "type"
end
