--food.lua
--handles the intake of food and drink

--Modding info:
--[[
 To add new foods, define your node(s), then pass a table with food info to
exile_add_food(table). Its on_use will be set automatically.
 Make sure all your nodes have been defined BEFORE you send any tables!
 exile_add_food() will override a node's on_use.

 For cookable things, define the node, and a name_cooked/name_burned version,
then pass the cooking data to exile_add_bake(table). Don't forget to add the
cooked version to the food table.
 If the burned version is not also added to foods, it will be inedible.
 exile_add_bake() will override a node's on_construct and on_timer.

 If a food can only be cooked in a pot, don't define a name_cooked node,
but add it to the food table anyway. The cooking pot will make a soup using
the food table's data, but the food will not be able to bake in an oven or
over a fire.
#TODO: Test this ^^ after the cooking pot supports both tables
]]--

-- Internationalization
local S = HEALTH.S

dofile(minetest.get_modpath('health')..'/data_food.lua')

-- Declare globals
food_harm_table = food_harm_table
food_table = food_table
bake_table = bake_table

local function do_food_harm(user, name)
  if type(name) == "userdata" and name["get_name"] then
    name = name:get_name()
  end
  local fht = food_harm_table[name] -- food_harm_table
  if not fht then return end
  if #fht == 0 then return end -- no effects
  local g_ch = fht.ch or fht.chance -- "global" chance (for all noted effects in table)
  local g_sv = fht.sv or fht.severity -- "global" severity (ditto /\)
  -- look through fht
  for ind,eff in pairs(fht) do -- for effect tables
    if type(eff) == "table" and type(ind) == "number" then -- do not conflict with "globals"
      -- chance (assume default of 0.001)
      local ch = eff.ch or eff.chance or g_ch or 0.001
      if math.random() <= ch then
        -- disease time
        -- severity (assume default of 1)
        local sv = eff.sv or eff.severity or g_sv or 1
        if type(sv) == "table" then
          -- is a chance, decide what severity it should be
          sv = math.random(sv[1],sv[2])
        end
        -- integers only
        sv = math.floor(sv)
        -- health effect tag (string or table, is made into table for the following)
        local tg = eff.tg or eff.tag or eff.tgs or eff.tags
        tg = type(tg) == "string" and {tg} or type(tg) == "table" and tg or nil
        -- table allows for you to specify numerous health effects with the same severity or chance
        if tg then
          for _,tg_name in pairs(tg) do
            if type(tg_name) == "string" then
              -- only strings allowed
              HEALTH.add_new_effect(user, {tg_name, sv})
            end
          end
        end
      end
    end
  end
end

-- does the reverse of do_food_harm but uses the same functions basically
local function do_food_cure(user, name)
  if type(name) == "userdata" and name["get_name"] then
    name = name:get_name()
  end
  local fct = HEALTH.cure_table[name]
  if not fct then return end
  local g_ch = fct.ch or fct.chance -- "global" chance (for all noted effects in table)
  local g_sv = fct.sv or fct.severity -- "global" severity (ditto /\)
  -- look through fct
  for ind,eff in pairs(fct) do -- for effect tables
    if type(eff) == "table" and type(ind) == "number" then -- do not conflict with "globals"
      -- chance (assume default of 0.001)
      local ch = eff.ch or eff.chance or g_ch or 0.001
      if math.random() <= ch then
        -- cure time
        -- severity (assume default of 1)
        local sv = eff.sv or eff.severity or g_sv or 1
        if type(sv) == "table" then
          -- is a chance, decide what severity it should cure
          sv = math.random(sv[1],sv[2])
        end
        -- integers only
        sv = math.floor(sv)
        -- health effect tag (string or table, is made into table for the following)
        local tg = eff.tg or eff.tag or eff.tgs or eff.tags
        tg = type(tg) == "string" and {tg} or type(tg) == "table" and tg or nil
        -- table allows for you to specify numerous health effects with the same severity or chance
        if tg then
          for _,tg_name in pairs(tg) do
            if type(tg_name) == "string" then
              -- only strings allowed
              HEALTH.remove_new_effect(user, {tg_name, sv})
            end
          end
        end
      end
    end
  end
end


function exile_eatdrink_playermade(itemstack, user, pointed_thing)
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
  if type(name) ~= "string" then
    return
  end
  local ft = prefercooked and food_table[name.."_cooked"] or food_table[name] -- food table
  if not ft then return end
  local stats = {}
  stats.hp = ft.hp or ft.health or 0
  stats.th = ft.th or ft.thirst or 0
  stats.hu = ft.hu or ft.hun or ft.hunger or 0
  stats.en = ft.en or ft.energy or 0
  stats.temp = ft.temp or ft.temperature or 0
  return stats
end

function exile_eatdrink(itemstack, user, pointed_thing)
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


-- Overrides for edible and bakable nodes
local eat_redef = {
   --on_use = function(itemstack, user, pointed_thing)
		--return exile_eatdrink(itemstack, user, pointed_thing)
   --end
}

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

function exile_add_food(table)
   --Add new foods, mod must send a table in the food_data.lua format
   for k, v in pairs(table) do
      food_table[k] = v
      if minetest.registered_nodes[k] then
	 minetest.override_item(k, eat_redef)
      end
   end
end
function exile_add_bake(table)
   --Add new bakables, mod must send a table in the food_data.lua format
   for k, v in pairs(table) do
      bake_table[k] = v
      if minetest.registered_nodes[k] then
	 minetest.override_item(k, bake_redef)
      end
   end
end
function exile_add_harm(table)
   --Add new food harm, mod must send a table in the food_data.lua format
   for k, v in pairs(table) do
      food_harm_table[k] = v
   end
end

function exile_add_food_hooks(name)
   if food_table[name] then
      if minetest.get_item_group(name,'edible') == 0 then
	 minetest.log("warning", "No edible group set for "..name..", patching")
	 local groups = minetest.registered_items[name].groups or {}
	 groups.edible = 1
	 minetest.override_item(name, {
				   _use_tip = "Eat",
				   groups = groups
	 })
      end
   end
   if bake_table[name] then
      minetest.override_item(name, bake_redef)
   end
   if string.match(name, "_cooked") then
	 minetest.override_item(name, bake_redef)
   end
end

-- Add food hooks to all nodes in edible group
minetest.register_on_mods_loaded(function()
	for name,_ in pairs(minetest.registered_nodes) do
		if minetest.get_item_group(name,'edible') > 0 then
		   exile_add_food_hooks(name)
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
