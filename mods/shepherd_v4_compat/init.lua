-- Shepherd v4 Compatibility Module
-- Re-assigns shepherd labels to mapchunks based on node content from map.sqlite
-- Note: SQL stores mapblocks → convert to node positions → shepherd labels mapchunks

local mod_name = core.get_current_modname()
local mod_path = core.get_modpath(mod_name)

core.log("action", "[" .. mod_name .. "] Loading shepherd v4 compatibility...")

-- Load the label assignment system
dofile(mod_path .. "/shepherd_labels.lua")

core.log("action", "[" .. mod_name .. "] Loaded successfully")
