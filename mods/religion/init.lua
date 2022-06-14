-- religion/init.lua

-- Minetest mod: religion
-- See README.txt for licensing and other information.

-- Load support for game translation.
local S = minetest.get_translator("religion")

-- time in seconds before getting a responce from god
local pray_time = 2 

-- the higher the weight, higher is the probability of getting it 
local pray_responses = {
	{message="and nothing happens", weight=100},
	{message="and you feel refreshed", weight=20},
	{message="you feel how your faith is strengthened", weight=20},
	{message="a voice inside you tells you that god is dead, but you decide to ignore it", weight=20},
	{message="something inside you tells you that this is not working", weight=10},
	{message="and you feel a soft breeze that comforts you", weight=10},
}

-- calculate once the total weight of prayer responses 
local total_weight = 0;
for prayer = 1,#pray_responses do
	total_weight = total_weight + pray_responses[prayer].weight
end

-- reset prayers counter on respawn
minetest.register_on_respawnplayer(function(player)
	local meta = player:get_meta()
	meta:set_int("total_prayers", 0)
	meta:set_int("last_prayer", 0)
end)

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
	tiles = {"tech_thatch.png"},
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
		local current_player = player:get_player_name()
		local total_prayers = meta:get_int("total_prayers")
		local last_prayer = meta:get_int("last_prayer")
		local current_day = minetest.get_day_count()
		local lived_days = current_day - meta:get_int("char_start_date")

		if total_prayers == 0 or last_prayer < current_day then
			-- raise a prayer
			minetest.chat_send_player(current_player, S("You offer up a prayer to your god"))
			meta:set_int("total_prayers", total_prayers + 1)
			meta:set_int("last_prayer", current_day)
			-- wait before define what happens
			minetest.after(pray_time, function()
				local picked = math.random(0,total_weight)
				local blessing = ''
				local accumulator = 0
				for prayer = 1,#pray_responses do
					accumulator = accumulator + pray_responses[prayer].weight
					if picked <= accumulator then
						blessing = pray_responses[prayer].message
						break
					end
				end
				minetest.chat_send_player(current_player, S(blessing))
			end)
		else
			-- wait for another day
			minetest.chat_send_player(current_player, S("You have already said your prayers for today"))
		end
		
	end,
})


------------------------------------
--RECIPES

crafting.register_recipe({
	type = "crafting_spot",
	output = "religion:efigy",
	items = {"group:fibrous_plant 8", "tech:stick 6"},
	level = 1,
	always_known = true,
})