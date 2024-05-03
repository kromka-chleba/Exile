--food.lua
--handles the intake of food and drink

--Modding info:
--[[
 To add new foods, define your node(s), then pass a table with food info to
exile_add_food_hook(name,table). Its _on_use_item will be set automatically.
 Make sure all your nodes have been defined BEFORE you send any tables!
 exile_add_food_hook() will override a node's _on_use_item.

 For cookable things, define the node, and a name_cooked/name_burned version,
then pass the cooking data to HEALTH.add_bake(table). Don't forget to add the
cooked version to the food table.
 If the burned version is not also added to foods, it will be inedible.
 HEALTH.add_bake() will override a node's on_construct and on_timer.

 If a food can only be cooked in a pot, don't define a name_cooked node,
but add it to the food table anyway. The cooking pot will make a soup using
the food table's data, but the food will not be able to bake in an oven or
over a fire.
#TODO: Test this ^^ after the cooking pot supports both tables
]]--

HEALTH = HEALTH

-- Internationalization
local S = HEALTH.S

dofile(minetest.get_modpath('health')..'/data_food.lua')

-- Declare globals
local food_harm_table = HEALTH.harm_table
local food_table = HEALTH.food_table
local bake_table = HEALTH.bake_table

-- used to get health effect data for food_harm and food_cure
-- returns table with effect tables with their name ('tg'), severity ('sv'), and chance ('ch') listed
-- thusly sterilizing any issues and conforming them for better use
local function get_health_effect_data(datat,name) -- datatable (harm_table or cure_table), name/item
  name = type(name) == "string" and name or type(name) == "userdata" and type(name["get_name"]) == "function" and name:get_name() or nil
  local hed = datat[name]
  if not hed then return end
  if #hed == 0 then return end -- no data/effects
  local g_ch = hed.ch or hed.chance -- "global" chance (for all noted effects in table)
  local g_sv = hed.sv or hed.severity -- "global" severity (ditto /\)
  -- to be returned \/
  local effects = {}
  -- look through hed
  for ind,eff in pairs(hed) do -- for effect tables
    -- accept function arguments for HEDs
    if type(eff) == "function" then
      eff = eff() -- must be table return
    end
    if type(eff) == "table" and type(ind) == "number" then -- do not conflict with above "globals"
      -- chance (assume default of 0.001)
      local ch = eff.ch or eff.chance or g_ch or 0.001
      -- provide chance in case someone wishes to modify the chance after the fact
      -- severity (assume default of 1)
      local sv = eff.sv or eff.severity or g_sv or 1
      if type(sv) == "table" then
        -- is a chance, decide what severity it should be
        sv = math.random(sv[1],sv[2])
      end
      -- integers only
      sv = math.floor(sv)
      -- health effect tag (string or table, is made into table for conformity)
      local tg = eff.tg or eff.tag or eff.tgs or eff.tags
      tg = type(tg) == "string" and {tg} or type(tg) == "table" and tg or nil
      -- table allows for you to specify numerous health effects with the same severity or chance
      if tg then
        for _,tg_name in pairs(tg) do
          if type(tg_name) == "string" then
            -- only strings allowed
            effects[#effects + 1] = {tg=tg_name,sv=sv,ch=ch}
          end
        end
      end
    end
  end
  if #effects <= 0 then
    -- nothing to do! don't do anythin'!
    return
  end
  return effects
end

local function do_food_harm(user, name)
  local effects = get_health_effect_data(food_harm_table,name)
  if not effects then return end -- got nothin'
  -- iterate through effects and add upon chance
  for _,effect in pairs(effects) do
    if math.random() <= effect.ch then
      HEALTH.add_new_effect(user, {effect.tg, effect.sv})
    end
  end
end

-- does the reverse of do_food_harm, curing stuff instead :D
local function do_food_cure(user, name)
  local effects = get_health_effect_data(HEALTH.cure_table,name)
  if not effects then return end -- got nothin'
  -- iterate through effects and remove from player
  for _,effect in pairs(effects) do
    if math.random() <= effect.ch then
      HEALTH.remove_new_effect(user, {effect.tg, effect.sv})
    end
  end
end


function HEALTH.eatdrink_playermade(itemstack, user, pointed_thing)
   local imeta = itemstack:get_meta()
   local pname = user:get_player_name()
   local t = minetest.deserialize(imeta:get_string("eat_value"))
   if t == nil then minetest.log("warning", pname..
				    " ate an invalid food of type "..
				    itemstack:get_name())
      return
   end
   return HEALTH.use_item(itemstack, user, t)
end

-- helps to get direct proper value naming or 0 for each
function HEALTH.get_food_stats(name,prefercooked)
  if type(name) == "userdata" and type(name["get_name"]) == "function" then
    name = name:get_name()
  end
  local ft = type(name) == "table" and name or -- food_table
  prefercooked and food_table[name.."_cooked"] or food_table[name]
  if type(ft) ~= "table" then
    return
  end
  local stats = {}
  -- numbered indexes for legacy support
  stats.hp = ft.hp or ft.health or ft[1] or 0
  stats.th = ft.th or ft.thirst or ft[2] or 0
  stats.hu = ft.hu or ft.hun or ft.hunger or ft[3] or 0
  stats.en = ft.en or ft.energy or ft[4] or 0
  stats.temp = ft.temp or ft.temperature or ft[5] or 0
  stats.rwi = ft.replace_item or ft.replace_with_item or ft.rwi or ft[6] or ""
  stats.sound = ft.eat_sound or ft.sound or ft.es or "health_eat"
  if type(stats.sound) == "string" then
    stats.sound = {name=stats.sound, max_hear_distance = 3, gain = 0.25}
  end
  return stats
end

function HEALTH.eatdrink(itemstack, user, pointed_thing)
   local name = type(itemstack) == "string" and itemstack or itemstack:get_name()

   if minetest.registered_aliases[name] then
      name = minetest.registered_aliases[name]
   end
   if not food_table[name] then
      minetest.chat_send_player(user:get_player_name(),
				S("This is inedible."))
      return
   end
   do_food_harm(user, name)
   do_food_cure(user, name)
   local t = food_table[name]
   return HEALTH.use_item(itemstack, user, t)
end

local function bake_error(pos, selfname)
   local posstr = minetest.pos_to_string(pos)
   minetest.log("error", "Warning, attempting to use a bake timer at "..
		"pos: "..posstr..", set on a non-bakeable node:"..selfname)
end

local bake_redef = {
   on_construct = function(pos)
      local selfname = minetest.get_node(pos).name
      selfname = selfname:gsub("_cooked","") -- ensure we have the base name
      if bake_table[selfname] == nil then
	 bake_error(pos, selfname)
	 return true
      end
      ncrafting.start_bake(pos, bake_table[selfname][2])
   end,
   on_timer = function(pos, elapsed)
      local selfname = minetest.get_node(pos).name
      selfname = selfname:gsub("_cooked","") -- ensure we have the base name
      if bake_table[selfname] == nil then
	 bake_error(pos, selfname)
	 return true
      end
      return ncrafting.do_bake(pos, elapsed,
			       bake_table[selfname][1],
			       bake_table[selfname][2])
end}

function HEALTH.add_bake(table)
   --Add new bakables, mod must send a table in the food_data.lua format
   for k, v in pairs(table) do
      bake_table[k] = v
      if minetest.registered_nodes[k] then
	 minetest.override_item(k, bake_redef)
      end
   end
end
function HEALTH.add_harm(table)
   --Add new food harm, mod must send a table in the food_data.lua format
   for k, v in pairs(table) do
      food_harm_table[k] = v
   end
end

function HEALTH.add_food_hooks(name,info)
   -- Adds hooks for edible foods, as well as bakeable things
   if type(info) == "table" then
      food_table[name] = info
   end
   if minetest.get_item_group(name,'edible') == 0 and food_table[name] then
    minetest.log("warning", "No edible group set for "..name..", patching")
    local groups = minetest.registered_items[name].groups or {}
    groups.edible = 1
    minetest.override_item(name, {
      _use_tip = "Eat",
      groups = groups
    })
  end
   if bake_table[name] then
      minetest.override_item(name, bake_redef)
   end
   if string.match(name, "_cooked") then -- If it's cooked, it can burn
	 minetest.override_item(name, bake_redef)
   end
end

-- Add food hooks to all nodes in edible group
minetest.register_on_mods_loaded(function()
      for name,_ in pairs(minetest.registered_nodes) do
	 if minetest.get_item_group(name,'edible') > 0
	 or food_table[name] or bake_table[name] then
	    HEALTH.add_food_hooks(name)
	 end
      end
end)

-- Finalized table list
--Outputs a compilned list of all added foods to the minetest log, info level
minetest.after(1, function()
   minetest.log("info", "Finalized list of food_table entries:")
   for k, v in pairs(food_table) do
      if minetest.registered_nodes[k] then
	 minetest.log("info",k)
      end
   end
   minetest.log("info","-------")
   minetest.log("info", "Finalized list of bake_table entries:")
   for k, v in pairs(bake_table) do
      if not minetest.registered_nodes[k] then
	 minetest.log("info", "Bake table contains an undefined node: "..k)
      else
	 if minetest.registered_nodes[k.."_cooked"] then
	    minetest.log("info",k)
	 else
	    minetest.log("info", "undefined node (cooking pot only entry): "..
			    k.."_cooked")
	 end
      end
   end
   minetest.log("info","-------")
end)
