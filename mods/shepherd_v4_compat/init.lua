-- Shepherd v4 Compatibility Module
-- Re-assigns shepherd labels to mapchunks based on node content from map.sqlite
-- Note: SQL stores mapblocks → convert to node positions → shepherd labels mapchunks

local mod_name = core.get_current_modname()
local mod_path = core.get_modpath(mod_name)

core.log("action", "[" .. mod_name .. "] Loading shepherd v4 compatibility...")

-- Try to use insecure environment for SQL-based compatibility first
local secenv = core.request_insecure_environment()

if secenv then
    -- Load the label assignment system which uses SQL
    dofile(mod_path .. "/shepherd_labels.lua")
    core.log("action", "[" .. mod_name .. "] Loaded SQL-based compatibility successfully")
else
    core.log("warning", "[" .. mod_name .. "] Insecure environment not available, SQL-based compatibility disabled")
    core.log("warning", "[" .. mod_name .. "] Set shepherd_v4_use_lbm_fallback=true to enable LBM fallback")
end

-- Load LBM-based fallback (only activates if setting is enabled)
dofile(mod_path .. "/shepherd_lbm_compat.lua")

core.log("action", "[" .. mod_name .. "] Loaded successfully")
