
------------------------------------
--TOOLS
--for debug, and gameplay
------------------------------------

mobkit = mobkit



------------------------------------
--LIGHT METER
--get positon light
------------------------------------

local light_meter = function(user, pointed_thing)

  local name =user:get_player_name()
  local pos = user:get_pos()

	minetest.chat_send_player(name, minetest.colorize("#00ff00", "LIGHT MEASUREMENT:"))

  local measure = ((minetest.get_node_light({x = pos.x, y = pos.y, z = pos.z})) or 0)

  minetest.chat_send_player(name, minetest.colorize("#cc6600","LIGHT LEVEL = "..measure))
  --minetest.sound_play("ecobots2_tool_good", {gain = 0.2, pos = pos, max_hear_distance = 5})

end


minetest.register_craftitem("artifacts:light_meter", {
	description = "Light Meter",
	inventory_image = "artifacts_light_meter.png",
	stack_max = 1,

	on_use = function(itemstack, user, pointed_thing)
		light_meter(user, pointed_thing)
	end,
})

------------------------------------
-- General probe setup
------------------------------------

local function init_probe(user, pointed_thing)
  if pointed_thing.type ~= "node" then
    return
  end

  local under = minetest.get_node(pointed_thing.under)
  local node_name = under.name
  local param2 = under.param2
  local nodedef = minetest.registered_nodes[node_name]
  if not nodedef then
    return
  end
  local name = user:get_player_name()
  local meta = minetest.get_meta(pointed_thing.under)
  return  name, meta, node_name, nodedef, param2
end


------------------------------------
--TEMPERATURE PROBE
--get node temperature
------------------------------------

local temp_probe = function(user, pointed_thing)

   local name = init_probe(user, pointed_thing)
   if not name then
      return
   end
  local temp = climate.get_point_temp(pointed_thing.under)
  local measure = climate.get_temp_string(temp, user:get_meta())

  minetest.chat_send_player(name, minetest.colorize("#00ff00", "OBJECT TEMPERATURE MEASUREMENT:"))
  minetest.chat_send_player(name, minetest.colorize("#cc6600","TEMPERATURE = "))
  minetest.chat_send_player(name, minetest.colorize("#cc6600", measure))
  --minetest.sound_play("ecobots2_tool_good", {gain = 0.2, pos = pos, max_hear_distance = 5})
end


minetest.register_craftitem("artifacts:temp_probe", {
	description = "Temperature Probe",
	inventory_image = "artifacts_temp_probe.png",
  wield_image = "artifacts_temp_probe.png^[transformR90",
	stack_max = 1,

	on_use = function(itemstack, user, pointed_thing)
		temp_probe(user, pointed_thing)
	end,
})




------------------------------------
--FUEL PROBE
--get burn progress
------------------------------------

local fuel_probe = function(user, pointed_thing)

   local name, meta = init_probe(user, pointed_thing)
   if not name then
    return
  end

   local measure = meta:get_int("fuel")

  if measure <= 0 then
    minetest.chat_send_player(name, minetest.colorize("#cc6600","NOT MEASURABLE!"))
  else
    minetest.chat_send_player(name, minetest.colorize("#00ff00", "BURN UNITS REMAINING:"))
    minetest.chat_send_player(name, minetest.colorize("#cc6600", measure))
  end

end


minetest.register_craftitem("artifacts:fuel_probe", {
	description = "Fuel Probe",
	inventory_image = "artifacts_fuel_probe.png",
  wield_image = "artifacts_fuel_probe.png^[transformR90",
	stack_max = 1,

	on_use = function(itemstack, user, pointed_thing)
		fuel_probe(user, pointed_thing)
	end,
})

------------------------------------
--SMELTER PROBE
--get smelting progress
------------------------------------

local smelter_probe = function(user, pointed_thing)
  local name, meta, node_name = init_probe(user, pointed_thing)
  if not name then
     return
  end
  local measure = meta:get_int("roast")

  if measure <= 0 or node_name ~= 'tech:iron_and_slag' then
    minetest.chat_send_player(name, minetest.colorize("#cc6600","NOT MEASURABLE!"))
  else
    minetest.chat_send_player(name, minetest.colorize("#00ff00", "SMELTING UNITS REMAINING:"))
    minetest.chat_send_player(name, minetest.colorize("#cc6600", measure))
  end

end


minetest.register_craftitem("artifacts:smelter_probe", {
	description = "Smelter Probe",
	inventory_image = "artifacts_smelter_probe.png",
  wield_image = "artifacts_smelter_probe.png^[transformR90",
	stack_max = 1,

	on_use = function(itemstack, user, pointed_thing)
		smelter_probe(user, pointed_thing)
	end,
})



------------------------------------
--POTTERS PROBE
--get  progress
------------------------------------

local potters_probe = function(user, pointed_thing)
  local name, meta = init_probe(user, pointed_thing)
  if not name then
     return
  end

  local measure = meta:get("firing")
  if measure == nil then
     measure = meta:get_int("roast")
  else
     measure = tonumber(measure)
  end

  if measure <= 0 then
    minetest.chat_send_player(name, minetest.colorize("#cc6600","NOT MEASURABLE!"))
  else
    minetest.chat_send_player(name, minetest.colorize("#00ff00", "FIRING UNITS REMAINING:"))
    minetest.chat_send_player(name, minetest.colorize("#cc6600", measure))
  end

end


minetest.register_craftitem("artifacts:potters_probe", {
	description = "Potter's Probe",
	inventory_image = "artifacts_potters_probe.png",
  wield_image = "artifacts_potters_probe.png^[transformR90",
	stack_max = 1,

	on_use = function(itemstack, user, pointed_thing)
		potters_probe(user, pointed_thing)
	end,
})


------------------------------------
--CHEFS PROBE
--get cooking progress
------------------------------------

local chefs_probe = function(user, pointed_thing)
  local name, meta = init_probe(user, pointed_thing)
  if not name then
     return
  end

  local measure = meta:get_int("baking")

  if measure <= 0 then
    minetest.chat_send_player(name, minetest.colorize("#cc6600","NOT MEASURABLE!"))
  else
    minetest.chat_send_player(name, minetest.colorize("#00ff00", "COOKING UNITS REMAINING:"))
    minetest.chat_send_player(name, minetest.colorize("#cc6600", measure))
  end

end


minetest.register_craftitem("artifacts:chefs_probe", {
	description = "Chef's Probe",
	inventory_image = "artifacts_chefs_probe.png",
  wield_image = "artifacts_chefs_probe.png^[transformR90",
	stack_max = 1,

	on_use = function(itemstack, user, pointed_thing)
		chefs_probe(user, pointed_thing)
	end,
})

local function chat_display(name, label, value)
    minetest.chat_send_player(name, minetest.colorize("#00ff00", label))
    minetest.chat_send_player(name, minetest.colorize("#cc6600", value))
end

local function chat_warning(name, msg)
    minetest.chat_send_player(name, minetest.colorize("#cc6600", msg))
end

------------------------------------
--ADMINS PROBE
--get node groups
------------------------------------

local admins_probe = function(user, pointed_thing)
    local name, meta, node_name, nodedef, param2 = init_probe(user, pointed_thing)
    if not name then
        return
    end
    local groups = minetest.serialize(nodedef.groups)
    groups = groups:gsub("return ", "")
    groups = groups:gsub("{", "")
    groups = groups:gsub("}", "")
    groups = groups:gsub(",", ", ")
    chat_display(name, "GROUPS: ", groups)
end

------------------------------------
--FARMERS PROBE
--get growth progress
------------------------------------

local farmers_probe = function(user, pointed_thing)

  local name, meta, node_name, nodedef, param2 = init_probe(user, pointed_thing)
  if not name then
     return
  end

  local growth = meta:get_int("growth")
  local health = meta:get_int("health")
  local fertility = nodedef.groups.fertility
  local roots = nodedef.groups.roots
  local root_nr = meta:get_float("root_nr")

  local check_plant_type = function()
      if param2 < 64 then
          chat_display(name, "PLANT TYPE:", "Wild")
          return "wild"
      elseif param2 < 128 then
          chat_display(name, "PLANT TYPE:", "Domesticated")
          return "dom"
      else
          chat_display(name, "PLANT TYPE:", "Half-wild")
          return "half"
      end
  end

  local check_growth = function()
      if growth <= 0 then
          chat_warning(name, "PLANT GROWTH NOT MEASURABLE!")
      else
          chat_display(name, "GROWTH UNITS REMAINING:", growth)
      end
  end

  local check_health = function()
      if health <= 0 then
          chat_warning(name, "PLANT HEALTH NOT MEASURABLE!")
      else
          chat_display(name, "HEALTH:", health)
      end
  end

  if nodedef.groups.flora or nodedef.groups.mushroom then
      local plant_type = check_plant_type()
      if plant_type == "dom" or plant_type == "half" then
          check_growth()
          check_health()
      end
  elseif nodedef.groups.sediment and fertility then
      if nodedef.groups.wet_sediment == 1 then
          chat_display(name, "STATE:", "wet")
      elseif nodedef.groups.wet_sediment == 2 then
          chat_display(name, "STATE:", "salty")
      else
          chat_display(name, "STATE:", "dry")
      end
      chat_display(name, "FERTILITY:", fertility)
      if roots == 1 then
          chat_display(name, "ROOTS:", root_nr)
      end
  else
      chat_warning(name, "NOT MEASURABLE: NEEDS A PLANT OR SOIL")
  end

end


minetest.register_craftitem("artifacts:farmers_probe", {
	description = "Farmer's Probe",
	inventory_image = "artifacts_farmers_probe.png",
  wield_image = "artifacts_farmers_probe.png^[transformR90",
	stack_max = 1,

	on_use = function(itemstack, user, pointed_thing)
		farmers_probe(user, pointed_thing)
	end,
})




------------------------------------
--ANTIQUORIUM CHISEL
--able to dig granite etc, no good for anything else.
------------------------------------
minetest.register_tool("artifacts:antiquorium_chisel", {
	description = "Antiquorium Chisel",
	inventory_image = "artifacts_antiquorium_chisel.png",
	tool_capabilities = {
		full_punch_interval = 1.0,
		groupcaps={
			cracky = {times={[1]=6.5, [2]=5.5, [3]=4.50}, uses=600, maxlevel=3},
		},
		damage_groups = {fleshy = 1},
	},
	sound = {breaks = "tech_tool_breaks"},
})



------------------------------------
--SPYGLASS
-- temporary zoom
------------------------------------

--a quick look through
local function use_spyglass(player)

	player:set_fov(10, false)

	minetest.after(5, function()
			player:set_fov(0, false)
	end)

end


--  item
minetest.register_craftitem("artifacts:spyglass", {
	description = "Spyglass",
	inventory_image = "artifacts_spyglass.png",
	stack_max = 1,

	on_use = function(itemstack, user, pointed_thing)
		use_spyglass(user)
	end,
})



------------------------------------
--ANIMAL PROBE
--get condition of an animal
------------------------------------

local animal_probe = function(user, pointed_thing)

  if pointed_thing.type ~= "object" then
    return
  end

  local name = user:get_player_name()
  local pt_ref = pointed_thing.ref
  if minetest.is_player(pt_ref) then
	local pt_meta = pt_ref:get_meta()
	local stats = {
		health = pt_ref:get_hp(),
		hunger = (pt_meta:get_int('hunger')/1000*100)..'%',
		thirst = (pt_meta:get_int('thirst')/100*100)..'%',
		energy = (pt_meta:get_int('energy')/1000*100)..'%',
		body_temp = pt_meta:get_int('temperature'),
		effects = pt_meta:get_int('effects_num'),
	}
	minetest.chat_send_player(name, minetest.colorize("#00ff00", "PLAYER CONDITION:"))
	minetest.chat_send_player(name, minetest.colorize("#cc6600",
		"Health: "..stats.health..
		"    Energy: "..stats.energy..
		"    Body Temp: "..stats.body_temp..
		"    Hunger: "..stats.hunger..
		"    Thirst: "..stats.thirst..
		"    Effects: "..stats.effects
	))
  else
	local ent = pt_ref:get_luaentity()
  if (type(ent) == "nil") then
    return
  end
	if not ent.memory then -- not a mobkit entity with a memory
		return
	end
  local r_ent_hp = ent.hp
	local r_ent_e = mobkit.recall(ent,'energy')
	local r_ent_a = mobkit.recall(ent,'age')

	if not r_ent_e or not r_ent_a or not r_ent_hp then
		return
	end
	r_ent_e = math.floor(r_ent_e)
	r_ent_a = math.floor(r_ent_a)

	minetest.chat_send_player(name, minetest.colorize("#00ff00", "ANIMAL CONDITION:"))
	minetest.chat_send_player(name, minetest.colorize("#cc6600","Health: "..r_ent_hp.." units    Age: "..r_ent_a.. " sec    Energy: "..r_ent_e.." units"))
  end
end

minetest.register_craftitem("artifacts:animal_probe", {
	description = "Animal Probe",
	inventory_image = "artifacts_animal_probe.png",
  wield_image = "artifacts_animal_probe.png^[transformR90",
	stack_max = 1,

	on_use = function(itemstack, user, pointed_thing)
		animal_probe(user, pointed_thing)
	end,
})


-- Group probe (only for developers)
minetest.register_craftitem("artifacts:admins_probe", {
	description = "Admin's Probe",
	inventory_image = "artifacts_admins_probe.png",
  wield_image = "artifacts_admins_probe.png^[transformR90",
	stack_max = 1,

	on_use = function(itemstack, user, pointed_thing)
		admins_probe(user, pointed_thing)
	end,
})
