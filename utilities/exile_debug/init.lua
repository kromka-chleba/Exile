cheats = {}

local S = minetest.get_translator("cheats")

cheats.get_translator = S

cheats.settings = {
  hus = tonumber(minetest.settings:get("exile_hud_update")) or 0.5, -- hudupdateseconds
}

-- yay local files stuff
local pathstoload = {
  "tools.lua", -- Work In Progress
  "api.lua",
}

local modpath = minetest.get_modpath("cheats")



for _,path in pairs(pathstoload) do
  dofile(modpath.."/"..path)
end

