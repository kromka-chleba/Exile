An attempt to see if fabric would be good for tents. 
The answer: maybe... but probably not. 
But it was interesting.

--[[
minetest.register_node("tech:stick_platform", {
 description = S("Stick Platform"),
 drawtype = "nodebox",
 node_box = {
		type = "fixed",
		fixed = {
			{-0.5, 0.375, -0.5, -0.4375, 0.5, 0.5}, -- NodeBox1
			{0.4375, 0.375, -0.5, 0.5, 0.5, 0.5}, -- NodeBox2
			{-0.4375, 0.375, -0.5, 0.4375, 0.5, -0.4375}, -- NodeBox3
			{-0.4375, 0.375, 0.4375, 0.4375, 0.5, 0.5}, -- NodeBox4
			{-0.4375, 0.4375, 0.125, 0.4375, 0.5, 0.1875}, -- NodeBox5
			{-0.4375, 0.4375, -0.1875, 0.4375, 0.5, -0.125}, -- NodeBox6
			{-0.1875, 0.4375, 0.1875, -0.125, 0.5, 0.4375}, -- NodeBox7
			{0.125, 0.4375, 0.1875, 0.1875, 0.5, 0.4375}, -- NodeBox8
			{0.125, 0.4375, -0.4375, 0.1875, 0.5, -0.1875}, -- NodeBox9
			{-0.1875, 0.4375, -0.4375, -0.125, 0.5, -0.1875}, -- NodeBox10
			{-0.1875, 0.4375, -0.125, -0.125, 0.5, 0.125}, -- NodeBox11
			{0.125, 0.4375, -0.125, 0.1875, 0.5, 0.125}, -- NodeBox12
		}
	},
 tiles = {"tech_stick.png"},
 stack_max = minimal.stack_max_bulky * 3,
 paramtype = "light",
 floodable = true,
 on_flood = function(pos, oldnode, newnode)
   minetest.add_item(pos, ItemStack("tech:stick"))
   return false
 end,
 sunlight_propagates = true,
 groups = {choppy=2, dig_immediate=2, flammable=1, temp_pass = 1, temp_flow = 100},
 sounds = nodes_nature.node_sound_wood_defaults(),
})





minetest.register_node("tech:coarse_fabric", {
	description = S("Coarse Fabric"),
	tiles = {"tech_coarse_fabric.png"},
	stack_max = minimal.stack_max_medium *2,
	paramtype = "light",
  paramtype2 = "wallmounted",
	drawtype = "nodebox",
	node_box = {
		type = "fixed",
		fixed = {-0.5, -0.5, -0.5, 0.5, -0.4, 0.5},
	},
	groups = {dig_immediate = 3, falling_node = 1, temp_pass = 1, flammable = 1},
	sounds = nodes_nature.node_sound_leaves_defaults(),
})


minetest.register_node("tech:fine_fabric", {
	description = S("Fine Fabric"),
	tiles = {"tech_fine_fabric.png"},
	stack_max = minimal.stack_max_medium *2,
	paramtype = "light",
  paramtype2 = "wallmounted",
	drawtype = "nodebox",
	node_box = {
		type = "fixed",
		fixed = {-0.5, -0.5, -0.5, 0.5, -0.4, 0.5},
	},
	groups = {dig_immediate = 3, falling_node = 1, temp_pass = 1, flammable = 1},
	sounds = nodes_nature.node_sound_leaves_defaults(),
})

]]