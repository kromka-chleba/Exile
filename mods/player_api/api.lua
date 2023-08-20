-- Minetest 0.4 mod: player
-- See README.txt for licensing and other information.

-- Load support for MT game translation.
local S = minetest.get_translator("player_api")

player_monoids =  player_monoids
player_api = {}

-- Player animation blending
-- Note: This is currently broken due to a bug in Irrlicht, leave at 0
local animation_blend = 0

player_api.registered_models = { }

-- Local for speed.
local models = player_api.registered_models

function player_api.register_model(name, def)
	models[name] = def
end

-- stubs for old api functions
function player_api.register_skin_modifier(modifier_func)
end
function player_api.read_textures_and_meta(hook)
end

-- Player stats and animations
local player_model = {}
local player_textures = {}
local player_anim = {}
local player_sneak = {}
local player_crawl = {}

player_api.player_attached = {}

function player_api.get_animation(player)
	local name = player:get_player_name()
	return {
		model = player_model[name],
		textures = player_textures[name],
		animation = player_anim[name],
	}
end

function player_api.set_gender(player, gender)
	if not(gender) or gender == "random" then
		if math.random(2) == 1 then
			gender = "male"
		else
			gender = "female"
		end
	end
	local meta = player:get_meta()
	meta:set_string("gender", gender)
	return gender
end

function player_api.get_gender(player)
	local meta = player:get_meta()
	return meta:get_string("gender")
end

function player_api.get_gender_model(gender)
	local model
	if gender == "male" then
		if minetest.get_modpath("3d_armor")~=nil then
			model =  "3d_armor_character.b3d"
		else
			model = "character.b3d"
		end
	else
		if minetest.get_modpath("3d_armor")~=nil then
			model =  "3d_armor_female.b3d"
		else
			model = "character-f.b3d"
		end
	end
	return model
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
	local anim = player_anim[pname] or ""
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

-- Called when a player's appearance needs to be updated
function player_api.set_model(player, model_name)
	local name = player:get_player_name()
	local model = models[model_name]
	if model then
		if player_model[name] == model_name then
			return
		end
		player:set_properties({
			mesh = model_name,
			textures = player_textures[name] or model.textures,
			visual = "mesh",
			visual_size = model.visual_size or {x = 1, y = 1},
			collisionbox = model.collisionbox or {-0.3, 0.0, -0.3, 0.3, 1.7, 0.3},
			stepheight = model.stepheight or 0.6,
			eye_height = model.eye_height or 1.47,
		})
		player_api.set_animation(player, "stand")
	else
		player:set_properties({
			textures = {"player.png", "player_back.png"},
			visual = "upright_sprite",
			visual_size = {x = 1, y = 2},
			collisionbox = {-0.3, 0.0, -0.3, 0.3, 1.75, 0.3},
			stepheight = 0.6,
			eye_height = 1.625,
		})
	end
	player_model[name] = model_name
end

function player_api.set_textures(player, textures)
	local name = player:get_player_name()
	local model = models[player_model[name]]
	local model_textures = model and model.textures or nil
	player_textures[name] = textures or model_textures
	player:set_properties({textures = textures or model_textures})
end

function player_api.set_animation(player, anim_name, speed)
	local name = player:get_player_name()
	if player_anim[name] == anim_name then
		return
	end
	local model = player_model[name] and models[player_model[name]]
	if not (model and model.animations[anim_name]) then
		return
	end
	local anim = model.animations[anim_name]
	player_anim[name] = anim_name
	player:set_animation(anim, speed or model.animation_speed, animation_blend)
end

minetest.register_on_leaveplayer(function(player)
	local name = player:get_player_name()
	player_model[name] = nil
	player_anim[name] = nil
	player_textures[name] = nil
	player_sneak[name] = nil
	player_api.player_attached[name] = nil
end)

-- Localize for better performance.
local player_set_animation = player_api.set_animation
local player_attached = player_api.player_attached

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

local checked = {} -- cache surroundings for players that are still

local function check_player_surroundings(player, pos, name)
   local function its_a_liquid(def)
      if def.liquidtype == "source" or def.liquidtype == "flowing" then
	 return true
      else return false end
   end
   local cn = checked[name] or {}
   if cn.pos and vector.equals(cn.pos, pos) then
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
   checked[name] = { ["pos"] = pos, [1] = on_water,
      [2] = node_above_is_solid, [3] = no_crouching, [4] = is_flying }
   return on_water, node_above_is_solid, no_crouching, is_flying
   -- #TODO: Try using part of the swim animation for flying?
end

local prop_table = { -- select gender + t/f for crawling eye_height/collision
   ["male"] = {
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
local timer = 0
minetest.register_globalstep(function(dtime)
      for _, player in pairs(minetest.get_connected_players()) do
	 local name = player:get_player_name()
	 local model_name = player_model[name]
	 local model = model_name and models[model_name]
	 if model then -- Detect newly attached player, remove crawl state
	    if player_attached[name] and player_crawl[name] then
			toggle_crawl(player, name, false)
			player:set_bone_position("Head",
						 { x=0, y=6.3, z=0 },
						 { x=0, y=  0, z=0 })
	    end
	    if not player_attached[name] then
	       -- Is the player dead?
	       if player:get_hp() == 0 then
		  player_set_animation(player, "lay")
		  player:set_bone_position("Head",
					{ x=0, y=6.3, z=0 },
					{ x=0, y=  0, z=0 })
	       else
		     local player_pos = player:get_pos()
		     local controls = player:get_player_control()
		     local animation_speed_mod = model.animation_speed or 30

		     --Determine if the player is in a water node
		     local on_water, cant_stand, cant_crouch =
			check_player_surroundings(player, player_pos, name)

		     local moving =  controls.up or controls.down or
			controls.left or controls.right
		     local using_tool = controls.LMB or controls.RMB

		     local sneaking = controls.sneak

		     local cancrawl = not ( player_anim[name] == "lay" or
				       on_water == true or
				       cant_crouch == true )

		     if cant_stand and not player_crawl[name] and cancrawl then
			toggle_crawl(player, name, true)
		     elseif not cancrawl and player_crawl[name] then
			toggle_crawl(player, name, false)
		     end

		     if player_sneak[name] ~= controls.sneak then
			-- reset anim when switching sneak on/off. why??
			player_anim[name] = nil
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

		     player_set_animation(player,
					  animtable[on_water][moving]
					  [crawling][using_tool],
					  animation_speed_mod)
		     move_head(player, on_water or crawling)

		     if on_water and player_pos.y < 0 then
			timer = timer + dtime
			if timer > 1 then
			   player_pos.y = player_pos.y + 1
			   minetest.add_particlespawner(bubbles(player_pos))
			   timer = 0
			end
		     end
	       end
	    end
	 end
      end
end)

function player_api.get_gender_formspec(name)
	local text = S("Select your gender")

	local formspec = {
		"formspec_version[3]",
		"size[3.2,2.476]",
		"label[0.375,0.5;", minetest.formspec_escape(text), "]",
		"image_button_exit[0.375,1;1,1;player_male_face.png;btn_male;"..S("Male").."]",
		"image_button_exit[1.7,1;1,1;player_female_face.png;btn_female;"..S("Female").."]"
	}

	-- table.concat is faster than string concatenation - `..`
	return table.concat(formspec, "")
end

function player_api.select_gender(player_name)
    minetest.show_formspec(player_name, "player_api:gender", player_api.get_gender_formspec(player_name))
end

function player_api.set_texture(player)
	local cloth = player_api.compose_cloth(player)
	local gender = player_api.get_gender(player)
	local gender_model = player_api.get_gender_model(gender)
	player_api.registered_models[gender_model].textures[1] = cloth
	player_api.set_model(player, gender_model)
	if minetest.get_modpath("3d_armor")~=nil then
		--armor.default_skin = cloth
		local player_name = player:get_player_name()
		armor.textures[player_name].skin = cloth
	end
	player_api.set_textures(player, models[gender_model].textures)
end

minetest.register_on_player_receive_fields(function(player, formname, fields)
	if formname ~= "player_api:gender" then
		return
	end
	local gender
	if fields.btn_male or fields.btn_female then
		if fields.btn_male then
			gender = "male"
		else
			gender = "female"
		end
		player_api.set_gender(player, gender)
	else
		player_api.set_gender(player, "random")
	end
	player_api.set_base_textures(player) --set the default base_texture
	player_api.set_cloths(player) --set the default clothes
	player_api.set_texture(player)
end)

local invisible = {}

function player_api.set_invisible(player, vanish)
   local props = player:get_properties()
   if vanish then
      invisible[player:get_player_name()] = true
      props.nametag = " " -- blank out nametag
      player:set_properties(props)
      -- props.is_visible doesn't work on players, so shrink them to 0 size
      player_monoids.visual_size:add_change(player, {x=0, y=0, z=0},
					    "player_api:invis")
   else
      invisible[player:get_player_name()] = nil
      props.nametag = "" -- An empty tag defaults to player's name
      player:set_properties(props)
      player_monoids.visual_size:del_change(player,"player_api:invis")
   end
end

function player_api.is_invisible(player)
   if invisible[player:get_player_name()] then
      return true
   end
   return false
end
