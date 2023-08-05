-------------------------------------
--HEALTH

--[[
Two global step functions
Fast, and slow.

Fast applies environmental and action based effects (in on_actions)
Slow applies internal metabolism effects (here)
]]

------------------------------------

HEALTH = {}

-- Internationalization
HEALTH.S = minetest.get_translator("health")
HEALTH.FS = function(...)
    return minetest.formspec_escape(HEALTH.S(...))
end

dofile(minetest.get_modpath('health')..'/health_effects.lua')
dofile(minetest.get_modpath('health')..'/on_actions.lua')
dofile(minetest.get_modpath('health')..'/hud.lua')
dofile(minetest.get_modpath('health')..'/food.lua')


--frequency of updating and applying effects
local interval = 60

-----------------------------
-- function dump
local function math_clamp(...) -- num,min,max
  return minimal.math_clamp(...)
end

function HEALTH.typeof(obj)
  if (type(obj) == "userdata") then
    if (obj["is_player"]) then
      if (obj:is_player() == true) then
        return "player"
      else
        return "luaentity"
      end
    elseif (obj["get_wear"] and obj["get_stack_max"]) then
      return "itemstack"
    elseif (obj["get_int"] and obj["get_string"]) then
      return "metadata"
    elseif (obj["get_timeout"] and obj["get_elapsed"]) then
      return "nodetimer"
    end
  else
    return type(obj)
  end
end

-----------------------------
--Player Attibutes
--
--use standard values base, so it doesn't compound each time called
--Only adjusted values saved in player meta so they can be accessed without recalculating
--cf hunger etc which do get change and have no base value
local max_health = 20

local heal_rate = 1 -- 4
local thirst_rate = -1
local hunger_rate = -3 -- -2
local recovery_rate = 4 -- 5
local move = 0
local jump = 0

--no clothing temperature comfort zone
local temp_min = 18--20
local temp_max = 32--30

function HEALTH.get_default_attributes() -- for other scripts to utilize to get base attributes of a fresh player
  return {
    health = max_health,
    thirst = 100,
    hunger = 1000,
    energy = 1000,
    temperature = 37,
    oxygen = 10, -- for suffocation or drowning
    
    heal_rate = heal_rate,
    thirst_rate = thirst_rate,
    hunger_rate = hunger_rate,
    recovery_rate = recovery_rate,
    
    move = move,
    jump = jump,
    
    clothing_temp_min = temp_min,
    clothing_temp_max = temp_max,
  }
end

--e.g. for new players
function HEALTH.set_default_attributes(player)
	local meta = player:get_meta()
  
  local attrb = HEALTH.get_default_attributes()
  
  for name,value in pairs(attrb) do
    if (type(name) ~= "string") then
      name = tostring(name)
    end
    
    if (type(value) == "number" and name ~= "health") then
      value = math.ceil(value)
      
      meta:set_int(name,value)
    elseif (type(value) == "string") then
      meta:set_string(name,value)
    end
  end
end
function HEALTH.reset_attributes(...) -- ditto definition
  HEALTH.set_default_attributes(...)
end

function HEALTH.get_meta_stats(meta)
  assert(type(meta) == "userdata","health.get_meta_stats: meta/player is not a valid 'userdata'")
  if (HEALTH.typeof(meta) == "player") then
    meta = meta:get_meta()
  elseif not (HEALTH.typeof(meta) == "metadata") then
    error("health.get_meta_stats: invalid parameter given for meta/player")
  end
  
  local fields = meta:to_table().fields
  
  for key,value in pairs(fields) do -- apparently all data is turned into strings???
    value = tonumber(value) -- turn into a number to check if the thing is actually a number
    if (type(value) == "number") then
      fields[key] = value
    end
  end
  
  return fields
end

function HEALTH.get_player_stats(player)
  assert(type(player) == "userdata","get_player_stats: player is not a valid 'userdata'")
  assert(HEALTH.typeof(player) == "player","get_player_stats: player is not a 'player'")
  
  local meta = player:get_meta()
  
  local fields = HEALTH.get_meta_stats(meta)
  
  fields.health = player:get_hp()
  
  return fields,meta
end





function HEALTH.set_int(player,name,value)
  assert(type(player) == "userdata","health.set_int: player/meta is not a valid 'userdata'")
  local meta = player -- assumes "player" may be metadata
  if (HEALTH.typeof(player) == "player") then
    meta = player:get_meta()
  elseif not (HEALTH.typeof(player) == "metadata") then
    error("health.set_int: invalid parameter given for player/meta")
  end
  
  if (type(value) ~= "number") then
    value = 0
  end
  
  if (type(name) ~= "string") then
    name = tostring(name)
    name = string.lower(name)
  else
    name = string.lower(name)
  end
  
  if (meta:get(name) == nil) then
    return 0
  end
  
  value = math.ceil(value)
  
  if (name == "hunger" or name == "energy") then
    value = math_clamp(value,0,1000)
  elseif (name == "thirst" or name == "temperature") then
    value = math_clamp(value,0,100)
  end
  
  meta:set_int(name,value)
  
  return value -- return modified value
end

-- allows any code that depends on HEALTH to use modify_hp to reliably modify player health
function HEALTH.modify_hp(player,value)
  assert(type(player) == "userdata","health.modify_hp: player is not a valid 'userdata'")
  assert(type(player["is_player"]) == "function","health.modify_hp: player is not a 'player'")
  assert(player:is_player() == true,"health.modify_hp: player is not a 'player'")
  
  if (type(value) ~= "number") then
    value = 0
  end
  
  local phealth = player:get_hp()
  
  phealth = phealth + value
  
  phealth = math_clamp(phealth,0,20)
  
  player:set_hp(phealth)
  
  return phealth -- return modified health
end

-- allows any code that depends on HEALTH to use modify_int to reliably modify stats like hunger or thirst
function HEALTH.modify_int(player,name,value)
  assert(type(player) == "userdata","health.modify_int: player/meta is not a valid 'userdata'")
  local meta = player -- assumes "player" may be metadata
  if (HEALTH.typeof(player) == "player") then
    meta = player:get_meta()
  elseif not (HEALTH.typeof(player) == "metadata") then
    error("health.modify_int: invalid parameter given for player/meta")
  end
  
  if (type(value) ~= "number") then
    value = 0
  end
  
  if (type(name) ~= "string") then
    name = tostring(name)
    name = string.lower(name)
  else
    name = string.lower(name)
  end
  
  if (meta:get(name) == nil) then
    return 0
  end
  
  local stat = meta:get_int(name)
  
  stat = meta:get_int(name)
  
  value = math.ceil(value)
  
  return HEALTH.set_int(meta,name,(stat + value)) -- return modified value
end


-- malus & bonus (does not calculate illness)
function HEALTH.q_malus_bonus(player,meta)
  assert(HEALTH.typeof(player) == "player","health.q_malus_bonus: provided 'player' is not a player!")
  
  local name = player:get_player_name()
  local bstats = HEALTH.get_default_attributes() -- get base starting stats
  local stats = {}
  
  -- incase meta is not provided then
  if (HEALTH.typeof(meta) ~= "metadata") then
    meta = player:get_meta()
    stats = HEALTH.get_meta_stats(meta)
  else
    -- if meta is provided
    stats = HEALTH.get_meta_stats(meta)
  end
  
  -- player's current stats as variables
  local health = player:get_hp()
  local energy = stats.energy
  local hunger = stats.hunger
  local thirst = stats.thirst
  local temperature = stats.temperature
  
  -- base stats to prevent compounding
  local h_rate = bstats.heal_rate
	local t_rate = bstats.thirst_rate
	local hun_rate = bstats.hunger_rate
	local r_rate = bstats.recovery_rate
	local mov = bstats.move
	local jum = bstats.jump
  
  
  --(hunger/Energy has 10x stock)
	--0-20 starving/severe dehydrated: malus, no heal
	--20-40 malnourished/dehydrated: malus
	--40-60 hungry/thirsty: small malus
	--60-80 good:
	--80-100 overfull: small malus

	--80-100 well rested. bonus
	--60-80 rested.
	--40-60 tired. small malus
	--20-40 fatigued. malus
	--0-20 exhausted. malus no heal

	--<27 death
	--27-32: severe hypo. malus no heal
	--32-37: hypothermia. malus
	--36-38: normal
	--38-43: hyperthermia. malus.
	--43-47: severe heat stroke. malus no heal
	-->47 death

	--
	--update rates
	--

	--bonus/malus from health
	if health <= 1 then
		mov = mov - 50
		jum = jum - 50
		h_rate = h_rate - 3
		r_rate = r_rate - 4
	elseif health < 4 then
		mov = mov - 25
		jum = jum - 25
		h_rate = h_rate - 2
		r_rate = r_rate - 2
	elseif health < 8 then
		mov = mov - 20
		jum = jum - 20
		h_rate = h_rate - 1
		r_rate = r_rate - 1
	elseif health < 12 then
		mov = mov - 15
		jum = jum - 15
	elseif health < 16 then
		mov = mov - 10
		jum = jum - 10
	end

	--bonus/malus from energy
	if energy > 800 then
		h_rate = h_rate + 2
		mov = mov + 15
		jum = jum + 15
	elseif energy < 1 then
		h_rate = h_rate - 1
		mov = mov - 40
		jum = jum - 40
		t_rate = t_rate - 12
		hun_rate = hun_rate - 24
	elseif energy < 200 then
		h_rate = h_rate - 1
		mov = mov - 20
		jum = jum - 20
		t_rate = t_rate - 4
		hun_rate = hun_rate - 8
	elseif energy < 400 then
		mov = mov - 10
		jum = jum - 10
		t_rate = t_rate - 3
		hun_rate = hun_rate - 4
	elseif energy < 600 then
		mov = mov - 5
		jum = jum - 5
		t_rate = t_rate - 2
		hun_rate = hun_rate - 2
	elseif energy < 700 then
		hun_rate = hun_rate - 1
	end


	--bonus/malus from thirst
	if thirst > 80 then
		h_rate = h_rate + 1
		r_rate = r_rate + 2
		mov = mov + 1
		jum = jum + 1
	elseif thirst < 1 then
		h_rate = h_rate - 12
		r_rate = r_rate - 10
		mov = mov - 30
		jum = jum - 30
	elseif thirst < 20 then
		h_rate = h_rate - 2
		r_rate = r_rate - 2
		mov = mov - 20
		jum = jum - 20
	elseif thirst < 40 then
		h_rate = h_rate - 1
		r_rate = r_rate - 1
		mov = mov - 10
		jum = jum - 10
	elseif thirst < 60 then
		mov = mov - 1
		jum = jum - 1
	end

	--bonus/malus from hunger
	if hunger > 800 then
		h_rate = h_rate + 1
		r_rate = r_rate + 2
		mov = mov + 1
		jum = jum + 1
	elseif hunger < 1 then
		h_rate = h_rate - 12
		r_rate = r_rate - 10
		mov = mov - 30
		jum = jum - 30
	elseif hunger < 200 then
		h_rate = h_rate - 2
		r_rate = r_rate - 2
		mov = mov - 20
		jum = jum - 20
	elseif hunger < 400 then
		h_rate = h_rate - 1
		r_rate = r_rate - 1
		mov = mov - 10
		jum = jum - 10
	elseif hunger < 600 then
		mov = mov - 1
		jum = jum - 1
	end

	--temp malus..severe..having this happen would make you very ill
	if temperature >= 100 or temperature <= 0 then -- now will cause immediate death
		--you dead
		h_rate = h_rate - 10000
		r_rate = r_rate - 10000
		mov = mov - 10000
		jum = jum - 10000
	elseif temperature > 47 or temperature < 27 then
		h_rate = h_rate - 16
		r_rate = r_rate - 64
		mov = mov - 80
		jum = jum - 80
	elseif temperature > 43 or temperature < 32 then
		h_rate = h_rate - 8
		r_rate = r_rate - 32
		mov = mov - 40
		jum = jum - 40
	elseif temperature > 38 or temperature < 37 then
		h_rate = h_rate - 4
		r_rate = r_rate - 8
		mov = mov - 20
		jum = jum - 20
	end

  --apply player physics
  --don't do in bed or it buggers the physics
  if not bed_rest.player[name] then
    player_monoids.speed:add_change(player, 1 + (mov/100), "health:physics")
    player_monoids.jump:add_change(player, 1 + (jum/100), "health:physics")
  end
  
  -- set new rates
  stats.heal_rate = HEALTH.set_int(meta,"heal_rate",h_rate)
	stats.thirst_rate = HEALTH.set_int(meta,"thirst_rate",t_rate)
	stats.hunger_rate = HEALTH.set_int(meta,"hunger_rate",hun_rate)
	stats.recovery_rate = HEALTH.set_int(meta,"recovery_rate",r_rate)
	stats.move = HEALTH.set_int(meta,"move",mov)
	stats.jump = HEALTH.set_int(meta,"jump",jum)
  
  --return adjusted rates so can be applied if necessary
	return stats
end


--[[
-----------------------------
--Forms for sfinv
--only for bug testing


--get data and create form
local function sfinv_get(self, player, context)
	local meta = player:get_meta()

	local player_pos = player:get_pos()
	player_pos.y = player_pos.y + 0.6 --adjust to body height
	local enviro_temp = tostring(math.floor(climate.get_point_temp(player_pos)))

	local health = tostring(player:get_hp())
	local thirst = tostring(meta:get_int("thirst"))
	local hunger = tostring(meta:get_int("hunger"))
	local energy = tostring(meta:get_int("energy"))
	local temperature = tostring(meta:get_int("temperature"))
	local heal_rate = tostring(meta:get_int("heal_rate"))
	local thirst_rate = tostring(meta:get_int("thirst_rate"))
	local hunger_rate = tostring(meta:get_int("hunger_rate"))
	local recovery_rate = tostring(meta:get_int("recovery_rate"))
	local move = tostring(meta:get_int("move"))
	local jump = tostring(meta:get_int("jump"))



	local formspec = "label[0.1,0.1; Health: " .. health .. " / 20]"..
	"label[0.1,0.6; Thirst: " .. thirst .. " / 100]"..
	"label[0.1,1.1; Hunger: " .. hunger .. " / 1000]"..
	"label[0.1,1.6; Energy: " .. energy .. " / 1000]"..
	"label[0.1,2.1; Body Temperature: " .. temperature .. " C]"..
	"label[0.1,3.1; Move Speed: " .. move .. " % change]"..
	"label[0.1,3.6; Jumping: " .. jump .. " % change]"..

	"label[4,0.1; Heal Rate: " .. heal_rate .. " ]"..
	"label[4,0.6; Thirst Rate: " .. thirst_rate .. " ]"..
	"label[4,1.1; Hunger Rate: " .. hunger_rate .. " ]"..
	"label[4,1.6; Recovery Rate: " .. recovery_rate .. " ]"..
	"label[4,2.1; External Temperature: " .. enviro_temp .. " C]"..
	"button[4,3.1;1,1;toggle_health_hud;HUD]"
	--..
	--"textarea[0.5,5.1;6,6;;Active Effects:;"..active_list.." ]"

	return formspec
end



local function register_tab()
	sfinv.register_page("health:health_tab", {
		title = "Health",
		on_enter = function(self, player, context)
			sfinv.set_player_inventory_formspec(player)
		end,
		get = function(self, player, context)
			local formspec = sfinv_get(self, player, context)
			return sfinv.make_formspec(player, context, formspec, true)
		end
	})
end

register_tab()


]]

-----------------------------
--Applies Health Effects
--called by malus_bonus
--runs through player's current effects, runs the function for that effect
--takes all the same variables, and outputs as any effect may use them.
--adjusted outputs feed back into malus_bonus
local function do_effects_list(player, meta)
  
  local health = player:get_hp()
  
  local h_rate = meta:get_int("heal_rate")
  local r_rate = meta:get_int("recovery_rate")
  local t_rate = meta:get_int("thirst_rate")
  local hun_rate = meta:get_int("hunger_rate")
  local mov = meta:get_int("move")
  local jum = meta:get_int("jump")
  
  local energy = meta:get_int("energy")
  local thirst = meta:get_int("thirst")
  local hunger = meta:get_int("hunger")
  local temperature = meta:get_int("temperature")
  
	local effects_list = meta:get_string("effects_list")
	effects_list = minetest.deserialize(effects_list) or {}
  
  local stats = {}
  stats.health = health
  stats.heal_rate = h_rate
  stats.recovery_rate = r_rate
  stats.thirst_rate = t_rate
  stats.hunger_rate = hun_rate
  stats.move = mov
  stats.jump = jum
  stats.energy = energy
  stats.thirst = thirst
  stats.hunger = hunger
  stats.temperature = temperature

	if not effects_list then
		return stats
	end

	for _, effect in ipairs(effects_list) do

		local name = effect[1]
		local order = effect[2]


		----------
		if name == "Food Poisoning" then
			r_rate, mov, jum, temperature = HEALTH.food_poisoning(order, player, meta, effects_list, r_rate, mov, jum, temperature)
		end
    stats.recovery_rate = stats.recovery_rate + r_rate
    stats.move = stats.move + mov
    stats.jump = stats.jump + jum
    stats.temperature = stats.temperature + temperature
		----------
		if name == "Fungal Infection" then
			r_rate, mov, jum, temperature = HEALTH.fungal_infection(order, player, meta, effects_list, r_rate, mov, jum, temperature)
		end
    stats.recovery_rate = stats.recovery_rate + r_rate
    stats.move = stats.move + mov
    stats.jump = stats.jump + jum
    stats.temperature = stats.temperature + temperature

		----------
		if name == "Dust Fever" then
			r_rate, mov, jum, temperature = HEALTH.dust_fever(order, player, meta, effects_list, r_rate, mov, jum, temperature)
		end

		----------
		if name == "Drunk" then
			r_rate, mov, jum, h_rate, temperature = HEALTH.drunk(order, player, meta, effects_list, r_rate, mov, jum, h_rate, temperature)
		end

		----------
		if name == "Hangover" then
			mov, jum = HEALTH.hangover(order, player, meta, effects_list, mov, jum)
		end

		----------
		if name == "Intestinal Parasites" then
			r_rate, hun_rate = HEALTH.intestinal_parasites(order, player, meta, effects_list, r_rate, hun_rate)
		end

		----------
		if name == "Tiku High" then
			r_rate, hun_rate, mov, jum, temperature = HEALTH.tiku_high(order, player, meta, effects_list, r_rate, hun_rate, mov, jum, temperature)
		end
    

		----------
		if name == "Neurotoxicity" then
			mov, jum = HEALTH.neurotoxicity(order, player, meta, effects_list, mov, jum)
		end

		----------
		if name == "Hepatotoxicity" then
			mov, jum, r_rate, h_rate = HEALTH.hepatotoxicity(order, player, meta, effects_list, mov, jum, r_rate, h_rate)
		end
    

		----------
		if name == "Photosensitivity" then
			h_rate, r_rate = HEALTH.photosensitivity(order, player, meta, effects_list, h_rate, r_rate)
		end

		---------
		if name == "Meta-Stim" then
			h_rate, r_rate, hun_rate, t_rate = HEALTH.meta_stim(order, player, meta, effects_list, h_rate, r_rate, hun_rate, t_rate)
		end


  end
  
  stats.recovery_rate = r_rate
  stats.heal_rate = h_rate
  stats.hunger_rate = hun_rate
  stats.thirst_rate = t_rate
  stats.move = mov
  stats.jump = jum
  stats.temperature = temperature
  
	return stats

end


-- gets quick malus_bonus and adds sicknesses on top of it all
function HEALTH.malus_bonus(player,meta)
  local stats = HEALTH.q_malus_bonus(player,meta)
  
  local mov = stats.move
  local jum = stats.jump
  
  stats = do_effects_list(player,meta)
  
  for name,value in pairs(stats) do
    if (type(value) == "number") then
      HEALTH.set_int(meta,name,value)
    elseif (type(value) == "string") then
      meta:set_string(value)
    end
  end
  
  local HE_mov = stats.move
  local HE_jum = stats.jump
  
  if not bed_rest.player[name] then
		--split physics from hunger etc from that from health effects
		--this means quick_physics can fiddle with one half, without overriding the half from effects
		HE_mov = HE_mov - mov
		HE_jum = HE_jum - jum
		player_monoids.speed:add_change(player, 1 + (HE_mov/100), "health:physics_HE")
		player_monoids.jump:add_change(player, 1 + (HE_jum/100), "health:physics_HE")
	end
  
  return stats
end





-----------------------------
--Bonus Malus... so can be called whenever player status is changed
--takes standard rates and adjusts them based on player status.
--saves adjusted rates and applies physics.
--send it attributes to adjust by,
--also give name and meta, bc anything calling it should already have that
-- returns the adjusted rates so they can be used if desired
--
--[[
function HEALTH.malus_bonus(player, name, meta, health, energy, thirst, hunger, temperature)

	--use standard values, so it doesn't compound each time adjusted.
	--Only saved to player meta so they can be accessed without recalculating
	local h_rate = heal_rate
	local t_rate = thirst_rate
	local hun_rate = hunger_rate
	local r_rate = recovery_rate
	local mov = move
	local jum = jump


	--(hunger/Energy has 10x stock)
	--0-20 starving/severe dehydrated: malus, no heal
	--20-40 malnourished/dehydrated: malus
	--40-60 hungry/thirsty: small malus
	--60-80 good:
	--80-100 overfull: small malus

	--80-100 well rested. bonus
	--60-80 rested.
	--40-60 tired. small malus
	--20-40 fatigued. malus
	--0-20 exhausted. malus no heal

	--<27 death
	--27-32: severe hypo. malus no heal
	--32-37: hypothermia. malus
	--36-38: normal
	--38-43: hyperthermia. malus.
	--43-47: severe heat stroke. malus no heal
	-->47 death

	--
	--update rates
	--

	--bonus/malus from health
	if health <= 1 then
		mov = mov - 50
		jum = jum - 50
		h_rate = h_rate - 3
		r_rate = r_rate - 4
	elseif health < 4 then
		mov = mov - 25
		jum = jum - 25
		h_rate = h_rate - 2
		r_rate = r_rate - 2
	elseif health < 8 then
		mov = mov - 20
		jum = jum - 20
		h_rate = h_rate - 1
		r_rate = r_rate - 1
	elseif health < 12 then
		mov = mov - 15
		jum = jum - 15
	elseif health < 16 then
		mov = mov - 10
		jum = jum - 10
	end

	--bonus/malus from energy
	if energy > 800 then
		h_rate = h_rate + 2
		mov = mov + 15
		jum = jum + 15
	elseif energy < 1 then
		h_rate = h_rate - 1
		mov = mov - 40
		jum = jum - 40
		t_rate = t_rate - 12
		hun_rate = hun_rate - 24
	elseif energy < 200 then
		h_rate = h_rate - 1
		mov = mov - 20
		jum = jum - 20
		t_rate = t_rate - 4
		hun_rate = hun_rate - 8
	elseif energy < 400 then
		mov = mov - 10
		jum = jum - 10
		t_rate = t_rate - 3
		hun_rate = hun_rate - 4
	elseif energy < 600 then
		mov = mov - 5
		jum = jum - 5
		t_rate = t_rate - 2
		hun_rate = hun_rate - 2
	elseif energy < 700 then
		hun_rate = hun_rate - 1
	end


	--bonus/malus from thirst
	if thirst > 80 then
		h_rate = h_rate + 1
		r_rate = r_rate + 2
		mov = mov + 1
		jum = jum + 1
	elseif thirst < 1 then
		h_rate = h_rate - 12
		r_rate = r_rate - 10
		mov = mov - 30
		jum = jum - 30
	elseif thirst < 20 then
		h_rate = h_rate - 2
		r_rate = r_rate - 2
		mov = mov - 20
		jum = jum - 20
	elseif thirst < 40 then
		h_rate = h_rate - 1
		r_rate = r_rate - 1
		mov = mov - 10
		jum = jum - 10
	elseif thirst < 60 then
		mov = mov - 1
		jum = jum - 1
	end

	--bonus/malus from hunger
	if hunger > 800 then
		h_rate = h_rate + 1
		r_rate = r_rate + 2
		mov = mov + 1
		jum = jum + 1
	elseif hunger < 1 then
		h_rate = h_rate - 12
		r_rate = r_rate - 10
		mov = mov - 30
		jum = jum - 30
	elseif hunger < 200 then
		h_rate = h_rate - 2
		r_rate = r_rate - 2
		mov = mov - 20
		jum = jum - 20
	elseif hunger < 400 then
		h_rate = h_rate - 1
		r_rate = r_rate - 1
		mov = mov - 10
		jum = jum - 10
	elseif hunger < 600 then
		mov = mov - 1
		jum = jum - 1
	end

	--temp malus..severe..having this happen would make you very ill
	if temperature >= 100 or temperature <= 0 then -- now will cause immediate death
		--you dead
		h_rate = h_rate - 10000
		r_rate = r_rate - 10000
		mov = mov - 10000
		jum = jum - 10000
	elseif temperature > 47 or temperature < 27 then
		h_rate = h_rate - 16
		r_rate = r_rate - 64
		mov = mov - 80
		jum = jum - 80
	elseif temperature > 43 or temperature < 32 then
		h_rate = h_rate - 8
		r_rate = r_rate - 32
		mov = mov - 40
		jum = jum - 40
	elseif temperature > 38 or temperature < 37 then
		h_rate = h_rate - 4
		r_rate = r_rate - 8
		mov = mov - 20
		jum = jum - 20
	end

	--health effects
	local HE_mov
	local HE_jum
	h_rate, r_rate, t_rate, hun_rate, HE_mov, HE_jum, health, energy, thirst, hunger, temperature = do_effects_list(player, health, energy, thirst, hunger, temperature, h_rate, r_rate, t_rate, hun_rate,  mov, jum)


	--save adjusted rates for access (e.g. by a medical tab/equipment etc)
	meta:set_int("heal_rate", h_rate)
	meta:set_int("thirst_rate", t_rate)
	meta:set_int("hunger_rate", hun_rate)
	meta:set_int("recovery_rate", r_rate)
	meta:set_int("move", HE_mov)
	meta:set_int("jump", HE_jum)

	--apply player physics
	--don't do in bed or it buggers the physics
	if not bed_rest.player[name] then
		player_monoids.speed:add_change(player, 1 + (mov/100), "health:physics")
		player_monoids.jump:add_change(player, 1 + (jum/100), "health:physics")
		--split physics from hunger etc from that from health effects
		--this means quick_physics can fiddle with one half, without overriding the half from effects
		HE_mov = HE_mov - mov
		HE_jum = HE_jum - jum
		player_monoids.speed:add_change(player, 1 + (HE_mov/100), "health:physics_HE")
		player_monoids.jump:add_change(player, 1 + (HE_jum/100), "health:physics_HE")


	end

	--return adjusted rates so can be applied if necessary
	return h_rate, r_rate, t_rate, hun_rate, mov, jum, health, energy, thirst, hunger, temperature

end
--]]

-----------------------------
--Main
--
minetest.register_on_newplayer(function(player)
	HEALTH.set_default_attributes(player)
end)

function HEALTH.update_player_physics(player)
   --local name = player:get_player_name()
   local meta = player:get_meta()
   --local health = player:get_hp()
   --local thirst = meta:get_int("thirst")
   --local hunger = meta:get_int("hunger")
   --local energy = meta:get_int("energy")
   --local temperature = meta:get_int("temperature")
   HEALTH.malus_bonus(player,meta)
   --HEALTH.malus_bonus(player, name, meta, health, energy,
		      --thirst, hunger, temperature)
end

minetest.register_on_joinplayer(function(player)
	sfinv.set_player_inventory_formspec(player)

	--set physics etc
	HEALTH.update_player_physics(player)
	local meta = player:get_meta()
	local velo = meta:get_string("player_velocity")
	if velo ~= nil then
	   local velo_vec = minetest.string_to_pos(velo)
	   if velo_vec ~= nil then
	      player:add_velocity(velo_vec)
	   end
	   meta:set_string("player_velocity", "")
	end
end)


minetest.register_on_dieplayer(function(player)
	--redo physics (to clear what killed them)
	player_monoids.speed:del_change(player, "health:physics")
	player_monoids.jump:del_change(player, "health:physics")
	player_monoids.speed:del_change(player, "health:physics_HE")
	player_monoids.jump:del_change(player, "health:physics_HE")
	--clear Health effects list
	local meta = player:get_meta()
	meta:set_string("effects_list", "")
	meta:set_int("effects_num", 0)
end)

minetest.register_on_respawnplayer(function(player)
	HEALTH.set_default_attributes(player)
	sfinv.set_player_inventory_formspec(player)
	clothing:update_temp(player)
end)

minetest.register_on_leaveplayer(function(player, timed_out)
      --TODO: Find a way to save this on singleplayer or for 1st hosted player
      local meta = player:get_meta()
      local velo = player:get_velocity() or player:get_player_velocity()
      meta:set_string("player_velocity", minetest.pos_to_string(velo))
end)

if minetest.settings:get_bool("enable_damage") then
	--Main update values
	local timer = 0
	minetest.register_globalstep(function(dtime)
		timer = timer + dtime

		--run
		if timer > interval then

			for _,player in ipairs(minetest.get_connected_players()) do

				local name = player:get_player_name()
				local meta = player:get_meta()
				local health = player:get_hp()
				-- don't damage us if we're already dead
				if health > 0 and
				   player:get_armor_groups().immortal ~= 1 then
				local thirst = meta:get_int("thirst")
				local hunger = meta:get_int("hunger")
				local energy = meta:get_int("energy")
				local temperature = meta:get_int("temperature")


				--apply rate adjustments so they are correct for current player status
				--local h_rate, r_rate, t_rate, hun_rate, mov, jum, health, energy, thirst, hunger, temperature  = HEALTH.malus_bonus(player, name, meta, health, energy, thirst, hunger, temperature)
        local stats = HEALTH.malus_bonus(player,meta)
        
        energy = stats.energy
        temperature = stats.temperature

				--update
        local temperature1 = 0

				if temperature > 37 then
					temperature1 = temperature1 - 1
					if temperature > 47 then
						h_rate = h_rate - 1
					end

				elseif temperature < 37 then
					temperature1 = temperature1 + 1
					if temperature < 27 then
						h_rate = h_rate - 1
					end
				end


				--update
				--
				HEALTH.modify_hp(player,h_rate)
				HEALTH.modify_int(meta,"temperature",temperature1)
        HEALTH.modify_int(meta,"thirst",t_rate)        
        HEALTH.modify_int(meta,"hunger",hun_rate)
        HEALTH.modify_int(meta,"energy",r_rate)
				--update form so can see change while looking
				sfinv.set_player_inventory_formspec(player)


				end
			end
		end
		--reset
		if timer > interval then
			timer = 0
		end

	end)

end
