-- religion/init.lua

-- Minetest mod: religion
-- See README.txt for licensing and other information.

-- Load support for game translation.
local S = minetest.get_translator("religion")

creative = creative

--local gods = ['cthulhu','nyarlathotep','yog-sothot']

local function is_owner(pos, name)
	local owner = minetest.get_meta(pos):get_string("owner")
	if owner == "" or owner == name or minetest.check_player_privs(name, "protection_bypass") then
		return true
	end
	return false
end

minetest.register_node("religion:efigy", {
	description = S("Effigy"),
	inventory_image = "efigy_inv.png",
	wield_image = "efigy_inv.png",
	tiles = {"thatch.png"},
	stack_max = 1,
	drawtype = "nodebox",
	node_box = {
			type = "fixed",
			fixed = {
				{-0.3000, -0.3000, -0.5000,  0.3000,  0.3000, -0.4000}, -- NodeBox1
				{-0.2000, -0.2000, -0.4000,  0.2000,  0.2000,  0.3000}, -- NodeBox2
				{-0.0500, -0.0500, -0.3000,  0.0500,  0.0500,  0.3000}, -- NodeBox3
				--{-0.3750, -0.5000, -0.5000, -0.1250, -0.4375, -0.3750}, -- NodeBox4
				--{ 0.0625, -0.5000, -0.3125,  0.3125, -0.4375, -0.2500}, -- NodeBox5
				--{-0.3750, -0.5000, -0.3125, -0.1250, -0.4375, -0.2500}, -- NodeBox6
				--{-0.3750, -0.4375, -0.3125, -0.3125, -0.3125, -0.2500}, -- NodeBox7
				--{ 0.2500, -0.4375, -0.3125,  0.3125, -0.3125, -0.2500}, -- NodeBox8
			}
		},
	paramtype = "light",
	paramtype2 = "facedir",
	sunlight_propagates = true,
	walkable = true,
	groups = {dig_immediate = 2, attached_node = 1, temp_pass = 1, falling_node = 1},
	sounds = nodes_nature.node_sound_gravel_defaults(),

	can_dig = function(pos, player)
		local inv = minetest.get_meta(pos):get_inventory()
		local name = ""
		if player then
			name = player:get_player_name()
		end
		return is_owner(pos, name) and inv:is_empty("main")
	end,

})
