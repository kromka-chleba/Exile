-- Minetest 0.4 mod: player
-- See README.txt for licensing and other information.

-- Load support for MT game translation.
local S = minetest.get_translator("player_api")

player_monoids = player_monoids

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

player_api.player_attached = {}

function player_api.get_animation(player, name)
   if not name then
      name = player:get_player_name()
   end
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
	player_api.player_attached[name] = nil
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
