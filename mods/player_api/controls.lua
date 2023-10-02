triggers = triggers
player_monoids =  player_monoids
local fire_trigger = triggers.activate
local set_anim = player_api.set_animation
local get_anim = player_api.get_animation
local models = player_api.registered_models

-- Localize for better performance.
local player_attached = player_api.player_attached

local USE_KEY = "aux1" --  or "zoom" #TODO: Make it configurable

-- Prevent knockback for attached players
local old_calculate_knockback = minetest.calculate_knockback
function minetest.calculate_knockback(player, ...)
	if player_attached[player:get_player_name()] then
		return 0
	end
	return old_calculate_knockback(player, ...)
end

-- Particles for underwater players
local function bubbles(pl_pos)
   return {
      amount = 6,
      time = 1,
      minpos = pl_pos,
      maxpos = pl_pos,
      minvel = {x=0, y=0, z=0},
      maxvel = {x=1, y=5, z=1},
      minacc = {x=0, y=0, z=0},
      maxacc = {x=1, y=1, z=1},
      minexptime = 0.2,
      maxexptime = 1.0,
      minsize = 1,
      maxsize = 1.5,
      collisiondetection = false,
      vertical = false,
      texture = "bubble.png",
   }
end

--converts yaw to degrees
local function yaw_to_degrees(yaw)
	return(yaw * 180.0 / math.pi)
end

local last_look = {}

local function move_head(player, tilt_up)
	local look_at_dir = player:get_look_dir()
	local pname = player:get_player_name()
	local lastlook = last_look[pname]
	local anim = get_anim(player).animation or ""
	local anim_base = string.sub(anim, 1, 4)
	--apply change only if the pitch or anim changed
	if lastlook and look_at_dir.y == lastlook.dir.y and
	   anim_base == lastlook.anim then
		return
	else
		last_look[pname] = {}
		last_look[pname].dir = look_at_dir
		last_look[pname].anim = anim_base
	end
	local pitch = yaw_to_degrees(math.asin(look_at_dir.y))
	if pitch > 70 then pitch = 70 end
	if pitch < -50 then pitch = -50 end
	if tilt_up then
		pitch = pitch + 70
	end

	local head_rotation = {x= pitch, y= 0, z= 0} --the head movement {pitch, yaw, roll}
	local head_offset
	if minetest.get_modpath("3d_armor")~=nil then
		head_offset = 6.75
	else
		head_offset = 6.3
	end
	local head_position = {x=0, y=head_offset, z=0}
	--set the head movement
	player:set_bone_position("Head", head_position, head_rotation)
end

local checked = {} -- cache surroundings for players that are still

local function check_player_surroundings(player, pos, name)
   local function its_a_liquid(def)
      if def.liquidtype == "source" or def.liquidtype == "flowing" then
	 return true
      else return false end
   end
   local cn = checked[name] or {}
   if cn.pos and vector.equals(cn.pos, vector.round(pos)) then
      return cn[1], cn[2], cn[3], cn[4]
   end
   local mrn = minetest.registered_nodes

   local node_name = minetest.get_node(pos).name
   local pos_above = {x= pos.x, y= pos.y+1, z= pos.z}
   local node_name_above = minetest.get_node(pos_above).name
   local pos_below = {x= pos.x, y= pos.y-1, z= pos.z}
   local node_name_below = minetest.get_node(pos_below).name

   local node_def = mrn[node_name] or mrn["air"]
   local node_above_def = mrn[node_name_above] or mrn["ignore"]
   local node_below_def = mrn[node_name_below] or mrn["ignore"]

   local node_above_is_solid = false
   local no_crouching = node_def.climbable or
      node_above_def.climbable -- no crawling on ladders
   local is_flying = false
   if node_above_def.walkable == true and no_crouching == false then
      if ( node_above_def.drawtype == "normal" and -- above is solid
	   node_def.drawtype ~= "normal" ) then -- and we're not noclipping
	 node_above_is_solid = true
      end -- #TODO: elseif; handle nodeboxes with a raycast? other cases
   end
   local node_above_is_air = ( node_above_def.drawtype == "airlike" )
   if node_def.drawtype == "airlike" and node_above_is_air
      and node_below_def.drawtype == "airlike" then
      no_crouching = true -- approximate guess for player flying
      is_flying = true
   end
   local on_water = false
   if its_a_liquid(node_def) then
      local node_below_is_liquid = its_a_liquid(node_below_def)
      local node_above_is_liquid = its_a_liquid(node_above_def)
      if (node_below_is_liquid or not mrn[node_name_below]) then
	 -- #TODO: check y distance from floor to see if we should swim anyway
	 if ( mrn[node_name_above] and (node_above_is_air)) or
	    not node_above_is_liquid then
	    on_water = false
	 else
	    on_water = true
	 end
      end
   end
   if node_def and node_def.groups.trigger == 1 then
      fire_trigger(pos, player)
   end
   checked[name] = { ["pos"] = vector.round(pos), [1] = on_water,
      [2] = node_above_is_solid, [3] = no_crouching, [4] = is_flying }
   return on_water, node_above_is_solid, no_crouching, is_flying
   -- #TODO: Try using part of the swim animation for flying?
end


local function handle_use_key(player, ppos)
   local using_tool = false -- whether we've done a thing yet
   local witem = player:get_wielded_item()
   local eye_height = player:get_properties().eye_height
   ppos.y = ppos.y + eye_height
   local lookdir = vector.multiply(player:get_look_dir(), 4) -- out to 5 nodes?
   local pointpos = vector.add(ppos, lookdir)
   local pointed_thing = minetest.raycast(ppos, pointpos, false, false):next()
   local pointed_node
   if pointed_thing then
      pointed_node = minetest.get_node(pointed_thing.under)
      local pdef = minetest.registered_nodes[pointed_node.name]
      if pdef._on_use_node then -- use pointed node's definition first
	 using_tool = pdef._on_use_node(player, pointed_node,
					pointed_thing, witem)
      end
   end
   local wnm = witem:get_name()
   local wdef = minetest.registered_items[wnm]
   if not using_tool and wdef then
      if wdef._on_use_item then
	 using_tool = wdef._on_use_item(player, witem, pointed_thing)
      end
      if not using_tool and wdef.groups.edible then
	 using_tool = true
	 if wdef.groups.edible == 1 then
	    exile_eatdrink(witem, player, pointed_thing)
	 elseif wdef.groups.edible == 2 then
	    exile_eatdrink_playermade(witem, player, pointed_thing)
	 end
      end
   end
   if using_tool and not minimal.player_in_creative(player) then
      player:set_wielded_item(witem)
   end
   return
end

local prop_table = { -- select gender + t/f for crawling eye_height/collision
   ["male"] = { -- #TODO: move this into a monoid?
      [true ] = { eye_height = 0.73, collisionbox =
		     {-0.3, 0.0, -0.3, 0.3, 0.9, 0.3}},
      [false] = { eye_height = 1.45,  collisionbox =
		     {-0.3, 0.0, -0.3, 0.3, 1.7, 0.3}} },
   ["female"] = {
      [true ] = { eye_height = 0.70, collisionbox =
		     {-0.3, 0.0, -0.3, 0.3, 0.9, 0.3}},
      [false] = { eye_height = 1.38, collisionbox =
		     {-0.3, 0.0, -0.3, 0.3, 1.7, 0.3}} }
}

local player_sneak = {}
local player_crawl = {}

local function make_boolean_array_table(count, tablein)
   if count == 0 then return end
   if tablein == nil then tablein = {} end
   tablein[true] = {}
   tablein[false] = {}
   make_boolean_array_table(count-1,tablein[true])
   make_boolean_array_table(count-1,tablein[false])
   return tablein
end

local animtable = make_boolean_array_table(4)

--       InWater,Moving,Crawl,UsingTools
animtable[false][false][false][false] = "stand"
animtable[false][false][false][true ] = "mine"
animtable[false][false][true ][false] = "crouch"
animtable[false][false][true ][true ] = "crouch_mine"
animtable[false][true ][false][false] = "walk"
animtable[false][true ][false][true ] = "walk_mine"
animtable[false][true ][true ][false] = "crawl"
animtable[false][true ][true ][true ] = "crawl_mine"
animtable[true ][false][false][false] = "stand"
animtable[true ][false][false][true ] = "mine"
animtable[true ][false][true ][false] = "stand"
animtable[true ][false][true ][true ] = "mine"
animtable[true ][true ][false][false] = "swim"
animtable[true ][true ][false][true ] = "swim_mine"
animtable[true ][true ][true ][false] = "swim"
animtable[true ][true ][true ][true ] = "swim_mine"

local function toggle_crawl(player, name, state)
   local gender = player_api.get_gender(player)
   -- swap eye height/collision
   player:set_properties(prop_table[gender][state])
   if state == true then -- reduce movement speed
      player_monoids.speed:add_change(player,
				      0.3,
				      "force_crawl")
   else
      player_monoids.speed:del_change(player,
				      "force_crawl")
   end
   player_crawl[name] = state
end

-- Check each player and apply animations
local bub_timer = 0
local use_timer = {}
local spawnbubbles = false
minetest.register_globalstep(function(dtime)
      bub_timer = bub_timer + dtime
      if bub_timer > 1.0 then
	 spawnbubbles = true
	 bub_timer = 0
      end
      for _, player in pairs(minetest.get_connected_players()) do
	 local name = player:get_player_name()
	 local pinfo = get_anim(player, name)
	 local model_name = pinfo.model
	 local model = model_name and models[model_name]
	 if model then -- Detect newly attached player, remove crawl state
	    if player_attached[name] and player_crawl[name] then
			toggle_crawl(player, name, false)
			player:set_bone_position("Head",
						 { x=0, y=6.3, z=0 },
						 { x=0, y=  0, z=0 })
	    end
	    local controls = player:get_player_control()
	    if not player_attached[name] then
	       -- Is the player dead?
	       if player:get_hp() == 0 then
		  set_anim(player, "lay")
		  player:set_bone_position("Head",
					{ x=0, y=6.3, z=0 },
					{ x=0, y=  0, z=0 })
	       else
		     local player_pos = player:get_pos()
		     local animation_speed_mod = model.animation_speed or 30

		     --Determine if the player is in a water node
		     local on_water, cant_stand, cant_crouch =
			check_player_surroundings(player, player_pos, name)

		     local moving =  controls.up or controls.down or
			controls.left or controls.right
		     local using_tool = controls.LMB or controls.RMB

		     local sneaking = controls.sneak

		     local cancrawl = not ( pinfo.animation == "lay" or
				       on_water == true or
				       cant_crouch == true )

		     if cant_stand and not player_crawl[name] and cancrawl then
			toggle_crawl(player, name, true)
		     elseif not cancrawl and player_crawl[name] then
			toggle_crawl(player, name, false)
		     end

		     if player_sneak[name] ~= controls.sneak then
			-- reset anim when switching sneak on/off. why??
			-- player_anim[name] = nil
			player_sneak[name] = controls.sneak
			if controls.sneak  then -- Double tap to crawl
			   if ( not player_crawl[name] and cancrawl and
				minimal.click_count_ready(name, "crawl",
							  2, 1) ) then
			      toggle_crawl(player, name, true)
			   elseif ( not cant_stand ) and player_crawl[name] then
			      toggle_crawl(player, name, false)
			   end
			end
		     end
		     if ( controls.jump and player_crawl[name] and
			  not cant_stand ) then -- Stand when jumping
			toggle_crawl(player, name, false)
		     end
		     local crawling = player_crawl[name] or false

		     if sneaking or crawling then
			animation_speed_mod = animation_speed_mod / 2
		     end

		     if controls[USE_KEY] then
			using_tool = true
		     end

		     set_anim(player,
			      animtable[on_water][moving][crawling][using_tool],
			      animation_speed_mod)
		     move_head(player, on_water or crawling)

		     if on_water and player_pos.y < 0 then
			-- #TODO: use player surroundings instead of y pos
			if spawnbubbles then
			   player_pos.y = player_pos.y + 1
			   minetest.add_particlespawner(bubbles(player_pos))
			end
		     end
	       end
	    end
	    if not use_timer[name] then
	       use_timer[name] = 0
	    elseif use_timer[name] > 0 then
	       use_timer[name] = use_timer[name] - dtime
	    end
	    if controls[USE_KEY] and player:get_hp() > 0 then
	       if use_timer[name] <= 0 then
		  use_timer[name] = 1
		  local player_pos = player:get_pos()
		  handle_use_key(player, player_pos)
	       end
	    end

	 end
      end
      spawnbubbles = false
end)

minetest.register_on_leaveplayer(function(player)
	local name = player:get_player_name()
	player_sneak[name] = nil
	player_crawl[name] = nil
end)
