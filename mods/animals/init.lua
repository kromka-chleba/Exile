animals = {}

-- Internationalization
animals.S = minetest.get_translator("animals")

local path = minetest.get_modpath(minetest.get_current_modname())

dofile(path.."/crafts.lua")
dofile(path.."/api_capture.lua")
dofile(path.."/api.lua")

-- get each file in folder
local mobs_folder = minetest.get_dir_list(path.."/mobs")
for _,file in pairs(mobs_folder) do
   -- run any lua file inside of "animals/mobs"
   if file:sub(#file-3,#file) == ".lua" then
      dofile(path.."/mobs/"..file)
   end
end

---
--Food Web

--[[
   The aim is for mobs to be permanent populations,
   rather than spawning "ex nihilo".
   Therefore most are small animals with small ranges.
   Have actual food webs that keep them alive.

   Ocean:
   "plankton (water)" -> gundu -> sarkamos


   Caves:
   "invisibly small stuff" -> impethu -> kubwakubwa/darkasthaan-> darkasthaan

   Land:
   plants/dirt/sneachan -> pegasun

]]
