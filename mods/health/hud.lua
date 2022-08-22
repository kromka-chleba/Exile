----------------------------------------------------------------------
--HUD
----------------------------------------------------------------------

-- Internationalization
local S = HEALTH.S

local hud = {}
local overlaid = {}
local hudupdateseconds = tonumber(minetest.settings:get("exile_hud_update"))

local show_stats = minetest.settings:get_bool("exile_raw_stats")

local setup_hud = function(player)

	player:hud_set_flags({healthbar = false})
	local playername = player:get_player_name()
	
	local hud_vert_pos 		= -128	-- all HUD icon vertical position
	local hud_extra_y		= -16		-- pixel offset for hot/cold icons
	local hud_text_y		= 32		-- optional text stat offset
	
	local hud_health_x 		= -192
	local hud_hunger_x 		= -128
	local hud_thirst_x 		= -64
	local hud_energy_x 		=  0
	local hud_body_temp_x 	= 64
	local hud_air_temp_x	= 128
	local hud_sick_x		= 192
	
	local icon_scale = {x = 1, y = 1}	-- all HUD icon image scale
	
	local hud_data = {}
	
	hud[playername] = hud_data
	
	hud_data.p_health = player:hud_add({
		hud_elem_type = "image",
		scale = icon_scale,
		offset = {x = hud_health_x, y = hud_vert_pos},
		position = {x = .5, y = 1},
	    text = "health_fine.png"
	})
	
	hud_data.p_hunger = player:hud_add({
		hud_elem_type = "image",
		scale = icon_scale,
		offset = {x = hud_hunger_x, y = hud_vert_pos},
		position = {x = .5, y = 1},
	    text = "hunger_fine.png"
	})
	
	hud_data.p_thirst = player:hud_add({
		hud_elem_type = "image",
		scale = icon_scale,
		offset = {x = hud_thirst_x, y = hud_vert_pos},
		position = {x = .5, y = 1},
	    text = "thirst_fine.png"
	})
	
	hud_data.p_energy = player:hud_add({
		hud_elem_type = "image",
		scale = icon_scale,
		offset = {x = hud_energy_x, y = hud_vert_pos},
		position = {x = .5, y = 1},
	    text = "energy_fine.png"
	})
	
	hud_data.p_body_temp = player:hud_add({
		hud_elem_type = "image",
		scale = icon_scale,
		offset = {x = hud_body_temp_x, y = hud_vert_pos},
		position = {x = .5, y = 1},
	    text = "body_temp_fine.png"
	})
	
	hud_data.p_body_temp_type = player:hud_add({
		hud_elem_type = "image",
		scale = icon_scale,
		offset = {x = hud_body_temp_x, y = hud_vert_pos + hud_extra_y},
		position = {x = .5, y = 1},
	    text = "temp_normal.png"
	})
	
	hud_data.p_air_temp = player:hud_add({
		hud_elem_type = "image",
		scale = icon_scale,
		offset = {x = hud_air_temp_x, y = hud_vert_pos},
		position = {x = .5, y = 1},
	    text = "air_temp_fine.png"
	    
	})
	
	hud_data.p_air_temp_type = player:hud_add({
		hud_elem_type = "image",
		scale = icon_scale,
		offset = {x = hud_air_temp_x, y = hud_vert_pos + hud_extra_y},
		position = {x = .5, y = 1},
	    text = "temp_normal.png"
	    
	})
	
	hud_data.p_sick = player:hud_add({
		hud_elem_type = "image",
		scale = icon_scale,
		offset = {x = hud_sick_x, y = hud_vert_pos},
		position = {x = .5, y = 1},
	    text = "sick_fine.png"
	})
	
	if show_stats then
	
		hud_data.p_health_text = player:hud_add({
			hud_elem_type = "text",
			offset = {x = hud_health_x, y = hud_vert_pos + hud_text_y},
			number = stat_col,
			position = {x = .5, y = 1},
			text = ""
		})
	
		hud_data.p_hunger_text = player:hud_add({
			hud_elem_type = "text",
			offset = {x = hud_hunger_x, y = hud_vert_pos + hud_text_y},
			number = stat_col,
			position = {x = .5, y = 1},
			text = ""
		})
	
		hud_data.p_thirst_text = player:hud_add({
			hud_elem_type = "text",
			offset = {x = hud_thirst_x, y = hud_vert_pos + hud_text_y},
			number = stat_col,
			position = {x = .5, y = 1},
			text = ""
		})
	
		hud_data.p_energy_text = player:hud_add({
			hud_elem_type = "text",
			offset = {x = hud_energy_x, y = hud_vert_pos + hud_text_y},
			number = stat_col,
			position = {x = .5, y = 1},
			text = ""
		})
	
		hud_data.p_body_temp_text = player:hud_add({
			hud_elem_type = "text",
			offset = {x = hud_body_temp_x, y = hud_vert_pos + hud_text_y},
			number = stat_col,
			position = {x = .5, y = 1},
			text = ""
		})
	
		hud_data.p_air_temp_text = player:hud_add({
			hud_elem_type = "text",
			offset = {x = hud_air_temp_x, y = hud_vert_pos + hud_text_y},
			number = stat_col,
			position = {x = .5, y = 1},
			text = ""
	    
		})
	
		hud_data.p_sick_text = player:hud_add({
			hud_elem_type = "text",
			offset = {x = hud_sick_x, y = hud_vert_pos + hud_text_y},
			number = stat_col,
			position = {x = .5, y = 1},
			text = ""
		})
	end

end

minetest.register_on_joinplayer(function(player) setup_hud(player) end)

-- status indicator colors for use in stat display option

local stat_fine 	= 0xFFFFFF
local stat_slight 	= 0xFDFF46
local stat_problem 	= 0xFF8100
local stat_major 	= 0xDF0000
local stat_extreme	= 0x8008FF

local function color(v)
	local icon_col = "fine"
	local stat_col = stat_fine
	if v <= 20 then
		icon_col = "extreme"
		stat_col = stat_extreme
	elseif v <= 40 then
		icon_col = "major"
		stat_col = stat_major
	elseif v <= 60 then
		icon_col = "problem"
		stat_col = stat_problem
	elseif v <= 80 then
		icon_col = "slight"
		stat_col = stat_slight
	end
	return icon_col, stat_col
end

local function color_bodytemp(v)
	local icon_col = "fine"
	local stat_col = stat_fine
	local ttype = "temp_normal"
	if v > 47 or v < 27 then
		icon_col = "extreme"
		stat_col = stat_extreme
		if v > 47 then ttype = "temp_hot" end
		if v < 27 then ttype = "temp_cold" end
	elseif v > 43 or v < 32 then
		icon_col = "major"
		stat_col = stat_major
		if v > 43 then ttype = "temp_hot" end
		if v < 32 then ttype = "temp_cold" end
	elseif v > 38 or v < 37 then
		icon_col = "problem"
		stat_col = stat_problem
		if v > 38 then ttype = "temp_hot" end
		if v < 37 then ttype = "temp_cold" end
	end
	return icon_col, stat_col, ttype
end

local function color_envirotemp(v, meta)
	--make sure matches actual values used!
	local comfort_low = meta:get_int("clothing_temp_min")
	local comfort_high = meta:get_int("clothing_temp_max")
	local stress_low = comfort_low - 10
	local stress_high = comfort_high + 10
	local danger_low = stress_low - 40
	local danger_high = stress_high +40
	local overlay

	local icon_col = "fine"
	local stat_col = stat_fine
	local ttype = "temp_normal"

	if v > danger_high or v < danger_low then
		icon_col = "extreme"
		stat_col = stat_extreme
		if v > danger_high then ttype = "temp_hot" end
		if v < danger_low then ttype = "temp_cold" end
	elseif v > stress_high or v < stress_low then
		icon_col = "major"
		stat_col = stat_major
		if v > stress_high then ttype = "temp_hot" end
		if v < stress_low then ttype = "temp_cold" end
	elseif v > comfort_high or v < comfort_low then
		icon_col = "slight"
		stat_col = stat_slight
		if v > comfort_high then ttype = "temp_hot" end
		if v < comfort_low then ttype = "temp_cold" end
	end
	if v < stress_low then
	   overlay = "weather_hud_frost.png"
	   ttype = "temp_cold"
	end
	if v > stress_high then
	   overlay = "weather_hud_heat.png"
	   ttype = "temp_hot"
	end

	return icon_col, stat_col, ttype, overlay
end


local function health(player, hud_data)
	local v = player:get_hp()
	v = (v/20)*100
	local icon_col, stat_col = color(v)
	local t = v .." %"
	local hud = hud_data.p_health
	player:hud_change(hud, "text", "health_"..icon_col..".png")
	if show_stats then
		local hud2 = hud_data.p_health_text
		player:hud_change(hud2, "number", stat_col)
		player:hud_change(hud2, "text", t)
	end
end

local function energy(player, hud_data, meta)
	local v = meta:get_int("energy")
	v = (v/1000)*100
	local icon_col, stat_col = color(v)
	local t = v .." %"
	local hud = hud_data.p_energy
	player:hud_change(hud, "text", "energy_"..icon_col..".png")
	if show_stats then
		local hud2 = hud_data.p_energy_text
		player:hud_change(hud2, "number", stat_col)
		player:hud_change(hud2, "text", t)
	end
end

local function thirst(player, hud_data, meta)
	local v = meta:get_int("thirst")
	v = (v/100)*100
	local t = v .." %"
	local icon_col, stat_col = color(v)
	local hud =  hud_data.p_thirst
	player:hud_change(hud, "text", "thirst_"..icon_col..".png")
	if show_stats then
		local hud2 = hud_data.p_thirst_text
		player:hud_change(hud2, "number", stat_col)
		player:hud_change(hud2, "text", t)
	end
end

local function hunger(player,  hud_data, meta)
	local v = meta:get_int("hunger")
	v = (v/1000)*100
	local t = v .." %"
	local icon_col, stat_col = color(v)
	local hud =  hud_data.p_hunger
	player:hud_change(hud, "text", "hunger_"..icon_col..".png")
	if show_stats then
		local hud2 = hud_data.p_hunger_text
		player:hud_change(hud2, "number", stat_col)
		player:hud_change(hud2, "text", t)
	end
end


local function temp(player, hud_data, meta)
	local v = meta:get_int("temperature")
	local icon_col, stat_col, ttype, overlay = color_bodytemp(v)
	local t = climate.get_temp_string(v, meta)
	local hud =  hud_data.p_body_temp
	local hud2 = hud_data.p_body_temp_type
	player:hud_change(hud, "text", "body_temp_"..icon_col..".png")
	player:hud_change(hud2, "text", ttype..".png")
	if show_stats then
		local hud2 = hud_data.p_body_temp_text
		player:hud_change(hud2, "number", stat_col)
		player:hud_change(hud2, "text", t)
	end
end

local function do_overlay(player, pname, pos, overlay)
   local handle = player:hud_add({
	 name = overlay,
	 hud_elem_type = "image",
	 position = {x = 0, y = 0},
	 alignment = {x = 1, y = 1},
	 scale = { x = -100, y = -100},
	 z_index = hud.z_index,
	 text = overlay,
	 offset = {x = 0, y = 0}
   })
   overlaid[pname] = handle
end


local function enviro_temp(player, hud_data, meta)
	local pname = player:get_player_name()
	local player_pos = player:get_pos()
	player_pos.y = player_pos.y + 0.6 --adjust to body height
	local v = math.floor(climate.get_point_temp(player_pos))
	local icon_col, stat_col, ttype, overlay = color_envirotemp(v, meta)
	if overlay then
	   if not overlaid[pname] then
	      do_overlay(player, pname, player_pos, overlay)
	   elseif player:hud_get(overlaid[pname]) and
	      ( overlay ~= player:hud_get(overlaid[pname]).name ) then
	      -- direct transition from one overlay to another
	      player:hud_remove(overlaid[pname])
	      do_overlay(player, pname, player_pos, overlay)
	   end
	elseif overlaid[pname] then -- remove overlay
	   player:hud_remove(overlaid[pname])
	   overlaid[pname] = nil
	end
	local t = climate.get_temp_string(v, meta)
	local newhud = hud_data.p_air_temp
	local newhud2 = hud_data.p_air_temp_type
	player:hud_change(newhud, "text", "air_temp_"..icon_col..".png")
	player:hud_change(newhud2, "text", ttype..".png")
	if show_stats then
		local hud2 = hud_data.p_air_temp_text
		player:hud_change(hud2, "number", stat_col)
		player:hud_change(hud2, "text", t)
	end
end

local function effects(player, hud_data, meta)
	local icon_col = "fine"
	local stat_col = stat_fine
	local v = meta:get_int("effects_num")
	local t = "x"..v
	if v > 0 then
		icon_col = "slight"
		stat_col = stat_slight
	elseif v > 1 then
		icon_col = "problem"
		stat_col = stat_problem
	elseif v > 2 then
		icon_col = "major"
		stat_col = stat_major
	elseif v > 3 then
		icon_col = "extreme"
		stat_col = stat_extreme
	end
	local hud = hud_data.p_sick
	player:hud_change(hud, "text", "sick_"..icon_col..".png")
	if show_stats then
		local hud2 = hud_data.p_sick_text
		player:hud_change(hud2, "number", stat_col)
		player:hud_change(hud2, "text", t)
	end
end

local timer = 0

minetest.register_globalstep(function(dtime)
  timer = timer + dtime

  if timer > hudupdateseconds then
   for _0, player in ipairs(minetest.get_connected_players()) do

		local name = player:get_player_name()
		local meta = player:get_meta()
		local hud_data = hud[name]
		if not hud_data then
			return
		end

		health(player, hud_data)
		energy(player, hud_data, meta)
		thirst(player, hud_data, meta)
		hunger(player, hud_data, meta)
		temp(player, hud_data, meta)
		enviro_temp(player, hud_data, meta)
		effects(player, hud_data, meta)

   end
   timer = 0
   return nil
  end
end)

