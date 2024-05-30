---------------------------------------------------
--STORAGE
--e.g. for chests, pots etc

artifacts = artifacts
local S = artifacts.S

---------------------------------------------------
--[[
local function get_storage_formspec(pos, w, h)
	local main_offset = 0.85 + h

	local formspec = {
		--"size[8,7]",
		"size[8,11]",
		"list[current_name;main;0,0.2;"..w..","..h.."]",
		"list[current_player;main;0,"..main_offset..";8,2]",
		"listring[current_name;main]",
		"listring[current_player;main]",}

	return table.concat(formspec, "")
end
--]]

----------------------------------------------------
--ANTIQUORIUM CHEST
----------------------------------------------------
storage.register_storage("artifacts:antiquorium_chest",{
  description = S("@1 chest", S("Antiquorium")),
	tiles = {"artifacts_antiquorium_chest_top.png",
			"artifacts_antiquorium_chest_bottom.png",
			"artifacts_antiquorium_chest_side.png",
			"artifacts_antiquorium_chest_side.png",
			"artifacts_antiquorium_chest_side.png",
			"artifacts_antiquorium_chest_side.png"},
	paramtype2 = "facedir",
  node_box = {
		type = "fixed",
		fixed = {
			{-0.5, -0.4375, -0.5, 0.5, -0.25, 0.5}, -- NodeBox1
			{-0.5, 0.375, -0.5, 0.5, 0.5, 0.5}, -- NodeBox2
			{-0.5, -0.5, -0.5, -0.3125, -0.4375, -0.3125}, -- NodeBox3
			{-0.5, -0.5, 0.3125, -0.3125, -0.4375, 0.5}, -- NodeBox4
			{0.3125, -0.5, 0.3125, 0.5, -0.4375, 0.5}, -- NodeBox5
			{0.3125, -0.5, -0.5, 0.5, -0.4375, -0.3125}, -- NodeBox6
			{-0.4375, -0.25, -0.4375, 0.4375, 0.375, 0.4375}, -- NodeBox7
		}
	},
  groups = {cracky = 1},
  sounds = nodes_nature.node_sound_glass_defaults(),
  
  -- formspec_width already defined in base register_storage as 8
  formspec_height = 8,
})
