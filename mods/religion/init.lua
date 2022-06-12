-- religion/init.lua

-- Minetest mod: religion
-- See README.txt for licensing and other information.

-- Load support for game translation.
local S = minetest.get_translator("religion")

local blessing_chance = 10 -- probability of getting a blessing 
local pray_time = 5 -- time in seconds before getting a responce from god

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
				{-0.3000, -0.5000, -0.3000,  0.3000, -0.4500,  0.3000}, -- NodeBox1
				{-0.2000, -0.4500, -0.2000,  0.2000, -0.4000,  0.2000}, -- NodeBox2
				{-0.0500, -0.1500, -0.0500,  0.0500,  0.3000,  0.0500}, -- NodeBox3
				{-0.3000,  0.0500, -0.0500,  0.3000,  0.1500,  0.0500}, -- NodeBox4
				{-0.1500, -0.4500, -0.0500, -0.0500, -0.0500,  0.0500}, -- NodeBox5
				{ 0.0500, -0.4500, -0.0500,  0.1500, -0.0500,  0.0500}, -- NodeBox6
				{-0.2500,  0.2500, -0.0250,  0.2500,  0.3000,  0.0250}, -- NodeBox7
				{-0.2500, -0.2500, -0.0250,  0.2500, -0.2000,  0.0250}, -- NodeBox8
				{ 0.2500, -0.2500, -0.0250,  0.3000,  0.3000,  0.0250}, -- NodeBox9
				{-0.2500, -0.2500, -0.0250, -0.3000,  0.3000,  0.0250}, -- NodeBox10
			}
		},
	paramtype = "light",
	paramtype2 = "facedir",
	light_source = 1,
	sunlight_propagates = true,
	walkable = true,
	drop = "tech:stick 6",
	groups = {snappy=3, flammable=1, falling_node = 1},
	sounds = nodes_nature.node_sound_wood_defaults(),

	can_dig = function(pos, player)
		local inv = minetest.get_meta(pos):get_inventory()
		local name = ""
		if player then
			name = player:get_player_name()
		end
		return is_owner(pos, name) and inv:is_empty("main")
	end,

	on_rightclick = function(pos, node, player, itemstack, pointed_thing)
		local meta = player:get_meta()
		local last_prayer_day = meta:get_int("last_prayer")
		local current_day = minetest.get_day_count()
		if( current_day > last_prayer_day) then
			-- raise a prayer
			minetest.chat_send_player(player:get_player_name(), S("You raise a prayer to your god"))
			meta:set_int("last_prayer", current_day)
			-- wait before define what happens
			minetest.after(pray_time, function()
				if(math.random(0,100) <= blessing_chance) then
					minetest.chat_send_all(S('@1 got a blessing!',player:get_player_name()))
					-- You god blesses you refilling all your needs
					-- TODO: there are a better way to do this? with health:quick_physics?
					meta:set_int("thirst", 100)
					meta:set_int("hunger", 1000)
					meta:set_int("energy", 1000)
					meta:set_int("temperature", 37)
				else
					-- Maybe this feedback can be skiped and just let nothing happen?
					minetest.chat_send_player(player:get_player_name(), S("and nothing happens"))
				end
			end)
		else
			-- wait for another day
			minetest.chat_send_player(player:get_player_name(), S("You have to wait before raise another prayer"))
		end
		
	end,
})


------------------------------------
--RECIPES

--sleeping_mat from cheap thatch
crafting.register_recipe({
	type = "crafting_spot",
	output = "religion:efigy",
	items = {"group:fibrous_plant 8", "tech:stick 6"},
	level = 1,
	always_known = true,
})