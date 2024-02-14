--------------------------------
--Inferno

-- Global namespace for functions

inferno = {}

-- Internationalization
local S = minetest.get_translator("inferno")

-- 'Enable fire' setting


local fire_enabled
local function check_enabled()
   fire_enabled = minetest.settings:get_bool("enable_fire")
   if fire_enabled == nil then
	-- enable_fire setting not specified, check for disable_fire
	local fire_disabled = minetest.settings:get_bool("disable_fire")
	if fire_disabled == nil then
		-- Neither setting specified, check whether singleplayer
		fire_enabled = minetest.is_singleplayer()
	else
		fire_enabled = not fire_disabled
	end
   end
   return fire_enabled
end
fire_enabled = check_enabled()

--
-- Items
--

-- Flood flame function

local function flood_flame(pos, oldnode, newnode)
   -- Play flame extinguish sound if liquid is not an 'igniter'
   if minetest.get_item_group(newnode.name, "flames") > 0 then
	minetest.sound_play("inferno_extinguish_flame",
			    {pos = pos, max_hear_distance = 16, gain = 0.15})
   end
   -- Remove the flame
   return false
end

local function burn_cane(pos)
   local above = vector.add(pos, vector.new(0,1,0))
   local anode = minetest.get_node(above)
   if minetest.get_item_group(anode.name, "cane_plant") > 0 then
      local tgt = minetest.find_node_near(above, 1, "group:air")
      if tgt then -- not at the top, extend the flames up
	 minetest.set_node(tgt, { name = "inferno:basic_flame"} )
	 return false -- didn't burn up yet
      end
   end
   -- at the top, burn this cane
   minetest.set_node(pos, { name = "inferno:basic_flame"} )
   return true -- fuel used
end

local function do_burn(flames, fuel_pos, fuel_def, fuel_node)
   local numflames = 1
   local fuelused = false
   if #flames > 0 then -- it's a pos table from the ABM
      numflames = #flames -- count how many are near
      flames = flames[math.random(1, #flames)] -- and pick one
   end

   -- multiplayer spread reduction, including no flame ignition
   if ( not minetest.is_singleplayer and
	math.random(1,5) > 3 and
	minetest.find_node_near(fuel_pos, 1, "group:igniter") == nil ) then
      minetest.remove_node(flames)
      return false
   end
   if not fuel_def then -- The flame timer doesn't know details of nearby fuel
      fuel_node = minetest.get_node(fuel_pos) -- so find one
      fuel_def = minetest.registered_nodes[fuel_node.name]
   end

   -- Check the flames versus flammability of this fuel node
   local roll = math.random(1, fuel_def.groups.flammable) - numflames
   if roll > 1 then -- 1 in x chance, increased by more flames
      minetest.remove_node(flames)
      return false
   end
   -- And now, the actual burn sequence
   if fuel_def.on_burn then -- first try on_burn
      fuel_def.on_burn(fuel_pos)
      fuelused = true
   elseif minetest.get_item_group(fuel_node.name,  -- then do tree ignition
				  "tree") >= 1
      or minetest.get_item_group(fuel_node.name, "log") >= 1 then
      minetest.set_node(fuel_pos, {name = "tech:large_wood_fire"})
      fuelused = true
      if math.random(1,4) == 1 then -- chance of branch collapse
	 minetest.check_for_falling(fuel_pos)
      end
   elseif minetest.get_item_group(fuel_node.name,  -- then handle cane ignition
				  "cane_plant") >= 1 then
      fuelused = burn_cane(fuel_pos)
   else -- finally, increase flames or burn up
      local air = minetest.find_node_near(fuel_pos, 1, {"group:air"})
      if air and math.random(1,10) < 8 then
	 -- 70% chance to add a fire if there's room, else burn up
	 minetest.set_node(air, {name = "inferno:basic_flame"})
      else -- no room/missed chance, burn up
	 minetest.remove_node(fuel_pos)
	 fuelused = true
      end
      if math.random(1,4) == 1 then
	 minetest.check_for_falling(fuel_pos)
      end
   end

   return true, fuelused
end

local function fire_timer(pos)
   local min = vector.new(vector.subtract(pos, 1))
   local max = vector.new(vector.add(pos, 1))
   local f = minetest.find_nodes_in_area(min, max,
					 "group:flammable")
   if not f or #f == 0 then
      minetest.remove_node(pos)
      return
   end

   --rain, water etc puts it out
   if (climate.get_rain(pos)
       or minetest.find_node_near(pos, 1,
				  {"group:puts_out_fire"})) then
      minetest.remove_node(pos)
      return
   end

   if not fire_enabled then
      local node = minetest.get_node(pos)
      if node.name == "inferno:basic_flame" then
	 local roll = math.random(1,8)
	 if roll <= 2 then
	    minetest.remove_node(pos)
	    return false
	 end
	 if roll <= 4 then
	    return true
	 end
      end
   end


   local fuel = f[math.random(1, #f)]

   local still_lit, fuel_used = do_burn(pos, fuel)
   if fuel_used then -- check again soon
      minetest.get_node_timer(pos):start(5)
   elseif still_lit then
      minetest.get_node_timer(pos):start(math.random(30, 60))
   end
end

-- Flame nodes

local flame_def = {
	drawtype = "firelike",
	tiles = {
		{
			name = "inferno_basic_flame_animated.png",
			animation = {
				type = "vertical_frames",
				aspect_w = 16,
				aspect_h = 16,
				length = 1
			},
		},
	},
	inventory_image = "inferno_basic_flame.png",
	paramtype = "light",
	light_source = 7,
	temp_effect = 50,
	temp_effect_max = 500,
	walkable = false,
	buildable_to = true,
	sunlight_propagates = true,
	floodable = true,
	damage_per_second = 4,
	groups = {igniter = 2, flames = 1, dig_immediate = 3,
		  not_in_creative_inventory = 1, timer = 47,
		  temp_effect = 1, temp_pass = 1},
	drop = "",

	on_timer = fire_timer,

	on_construct = function(pos)
	   minetest.get_node_timer(pos):start(math.random(3, 12))
	end,

	on_flood = flood_flame,
}

minetest.register_node("inferno:hungry_flame", flame_def)
if not fire_enabled then
   flame_def.groups = {flames = 1, dig_immediate = 3,
		       not_in_creative_inventory = 1,
		       temp_effect = 1, temp_pass = 1}
end

minetest.register_node("inferno:basic_flame", flame_def)


--
-- Sound
--

local flame_sound = minetest.settings:get_bool("flame_sound")
if flame_sound == nil then
	-- Enable if no setting present
	flame_sound = true
end

if flame_sound then

	local handles = {}
	local timer = 0

	-- Parameters

	local radius = 8 -- Flame node search radius around player
	local cycle = 3 -- Cycle time for sound updates

	-- Update sound for player

	function inferno.update_player_sound(player)
		local player_name = player:get_player_name()
		-- Search for flame nodes in radius around player
		local ppos = player:get_pos()
		local areamin = vector.subtract(ppos, radius)
		local areamax = vector.add(ppos, radius)
		local fpos, num = minetest.find_nodes_in_area(
			areamin,
			areamax,
			{"group:flames"}
		)
		-- Total number of flames in radius
		local flames = (num["inferno:basic_flame"] or 0)
		flames = flames + (num["inferno:hungry_flame"] or 0)
		-- Stop previous sound
		if handles[player_name] then
			minetest.sound_stop(handles[player_name])
			handles[player_name] = nil
		end
		-- If flames
		if flames > 0 then
			-- Find centre of flame positions
			local fposmid = fpos[1]
			-- If more than 1 flame
			if #fpos > 1 then
				local fposmin = areamax
				local fposmax = areamin
				for i = 1, #fpos do
					local fposi = fpos[i]
					if fposi.x > fposmax.x then
						fposmax.x = fposi.x
					end
					if fposi.y > fposmax.y then
						fposmax.y = fposi.y
					end
					if fposi.z > fposmax.z then
						fposmax.z = fposi.z
					end
					if fposi.x < fposmin.x then
						fposmin.x = fposi.x
					end
					if fposi.y < fposmin.y then
						fposmin.y = fposi.y
					end
					if fposi.z < fposmin.z then
						fposmin.z = fposi.z
					end
				end
				fposmid = vector.divide(vector.add(fposmin, fposmax), 2)
			end
			-- Play sound
			local handle = minetest.sound_play(
				"inferno_fire",
				{
					pos = fposmid,
					to_player = player_name,
					gain = math.min(0.06 * (1 + flames * 0.125), 0.18),
					max_hear_distance = 32,
					loop = true, -- In case of lag
				}
			)
			-- Store sound handle for this player
			if handle then
				handles[player_name] = handle
			end
		end
	end

	-- Cycle for updating players sounds

	minetest.register_globalstep(function(dtime)
		timer = timer + dtime
		if timer < cycle then
			return
		end

		timer = 0
		local players = minetest.get_connected_players()
		for n = 1, #players do
			inferno.update_player_sound(players[n])
		end
	end)

	-- Stop sound and clear handle on player leave

	minetest.register_on_leaveplayer(function(player)
		local player_name = player:get_player_name()
		if handles[player_name] then
			minetest.sound_stop(handles[player_name])
			handles[player_name] = nil
		end
	end)
end


--
-- ABM
--
-- Remove/convert flammable nodes around basic flame
--remember to set on_burn for the registered node where suitable
-- e.g. to turn trees into tech large fire

minetest.register_abm({
      label = "Ignite flammable nodes",
      nodenames = {"group:flammable"},
      neighbors = {"group:flames", "group:igniter"},
      interval = 23,
      chance = 9,
      catch_up = false,
      action = function(pos, node)
	 local function find_and_dieout()
	    -- fire spread is by igniter flames, if fire spread is disabled
	    -- then we only get igniter flames from lightning strike,
	    -- so remove regular flames over time
	    local f = minetest.find_node_near(pos, 1, "group:flames")
	    if f then
	       minetest.remove_node(f)
	    end
	    return
	 end

	 local flammable_node = node
	 local def = minetest.registered_nodes[flammable_node.name]

	 local ignition = minetest.find_node_near(pos, 1, "group:igniter")
	 if not ignition then find_and_dieout() return end

	 do_burn(ignition, pos, def, node)
      end,
})

-- QoL hack: no need to ignite each node separately.
minetest.register_abm({
	label = "Ignite nearby fires in a charcoal kiln",
	nodenames = {"tech:large_wood_fire_unlit",      "tech:small_wood_fire_unlit"},
	neighbors = {"tech:large_wood_fire_smoldering", "tech:small_wood_fire_smoldering"},
	interval = 11,
	chance = 3,
	catch_up = false,
	action = function(pos, flammable_node)
		local def = minetest.registered_nodes[flammable_node.name]
		if def.on_burn then
			def.on_burn(pos)
		end
	end,
})
--------------------------------------------------
-- Fire Starters
--

local function add_wear(player_name, itemstack, sound_pos)
	if not (minimal.player_in_creative(player_name)) then
		-- Wear tool
		local wdef = itemstack:get_definition()
		itemstack:add_wear(2000)
		-- Tool break sound
		if itemstack:get_count() == 0 and wdef.sound and wdef.sound.breaks then
		   minetest.sound_play(wdef.sound.breaks, {pos = sound_pos, gain = 0.5, max_hear_distance = 8})
		end
		return itemstack
	end

end

local lit = {
   ["tech:small_wood_fire_unlit"] = "tech:small_wood_fire",
   ["tech:large_wood_fire_unlit"] = "tech:large_wood_fire",
   ["tech:charcoal"] = "tech:small_charcoal_fire",
   ["tech:charcoal_block"] = "tech:large_charcoal_fire",
   ["tech:small_wood_fire_ext"] = "tech:small_wood_fire",
   ["tech:large_wood_fire_ext"] = "tech:large_wood_fire",
   ["tech:small_charcoal_fire_ext"] = "tech:small_charcoal_fire",
   ["tech:large_charcoal_fire_ext"] = "tech:large_charcoal_fire",
}

function inferno.ignite(pos, nodename)
   if nodename == nil or nodename == "" then
      nodename = minetest.get_node(pos).name
   end
   for unl, l in pairs(lit) do
      if nodename == unl then
	 minimal.switch_node(pos, {name = l})
	 return true
      end
   end
   return false
end

local function sound_play(spos)
   minetest.sound_play(
      "inferno_fire_sticks",
      {pos = spos, gain = 0.5, max_hear_distance = 8}
   )
end

-- Fire Sticks
minetest.register_tool("inferno:fire_sticks", {
	description = S("Fire Sticks"),
	inventory_image = "inferno_fire_sticks.png",
	sound = {breaks = "tech_tool_breaks"},

	on_use = function(itemstack, user, pointed_thing)
	   local sound_pos = pointed_thing.above or user:get_pos()
	   local player_name = user:get_player_name()
	   if pointed_thing.type ~= "node" then return itemstack end
	   local node_under = minetest.get_node(pointed_thing.under).name
	   local pos_under = pointed_thing.under
	   if inferno.ignite(pos_under, node_under) then
	      sound_play(sound_pos)
	      return add_wear(player_name, itemstack, sound_pos)
	   end

	   local nodedef = minetest.registered_nodes[node_under]
	   if not nodedef then
	      return
	   end
	   if minetest.is_protected(pointed_thing.under, player_name) then
	      minetest.chat_send_player(player_name, "This area is protected")
	      return
	   end
	   local chance = nodedef.groups.flammable
	   if (chance and chance < 6) or chance == nil then
	      if nodedef.on_ignite then
		 sound_play(sound_pos)
		 nodedef.on_ignite(pointed_thing.under, user)
		 return add_wear(player_name, itemstack, sound_pos)
	      elseif chance and minetest.get_node(pointed_thing.above).name
		 == "air" then
		 sound_play(sound_pos)
		 if math.random(1, chance) == 1 then
			 minetest.set_node(pointed_thing.above,
					   {name = "inferno:basic_flame"})
		 end
		 return add_wear(player_name, itemstack, sound_pos)
	      end
	   end
	   return itemstack
	end
})


---------------------------------------
--Recipes

--
--Hand crafts (Crafting spot)
--
minetest.register_on_mods_loaded(function()
      ----craft unlit fire from Sticks, tinder
      crafting.register_recipe({
	    type = "crafting_spot",
	    output = "inferno:fire_sticks",
	    items = {"tech:stick 2", "group:fibrous_plant 1"},
	    level = 1,
	    always_known = true,
      })
end)
