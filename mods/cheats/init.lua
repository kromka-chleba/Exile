cheats = {}

local S = minetest.get_translator("cheats")

cheats.get_translator = S

-- yay local files stuff
local pathstoload = {
  --"tools.lua", -- Work In Progress
  "api.lua",
}

local modpath = minetest.get_modpath("cheats")



for _,path in pairs(pathstoload) do
  if (type(path) == "string") then
    dofile(modpath.."/"..path)
  end
end

