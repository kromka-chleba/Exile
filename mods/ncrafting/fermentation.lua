-- fermentation.lua
------------------------------------
--FERMENTATION FUNCTIONALITY
-----------------------------------
-- Internationalization
local S = ncrafting.S
-- misc functions + globals
local random = math.random
climate = climate

-- BASIC FUNCTIONALITIES

ncrafting.ferment_interval = 5

function ncrafting.get_ferment_data(name)
  if type(name) == "userdata" and type(name["get_name"]) == "function" then
    name = name:get_name()
  elseif type(name) == "table" then
    if name.x and name.y and name.z then
      name = minetest.get_node(name)
    end
    name = name.name
  end
  if type(name) ~= "string" then return end
  local def = minetest.registered_nodes[name]
  if not def then return end
  local ferment_data = {
    to = def._ferment_to,
    time = def._ferment_time or {min=300,max=360},
    temp_range = def._ferment_temp_range,
  }
  if type(def._ferment_aerobic) == "boolean" then
    -- aerobic: true if need air, false if needs no air, nil if it doesn't matter
    ferment_data.aerobic = def._ferment_aerobic
  end
  return ferment_data
end

-- find ferment or create a ferment meta
function ncrafting.get_or_create_ferment(name,meta)
  local ferment = type(meta) == "userdata" and meta:get_int("ferment")
  or type(meta) == "table" and type(meta.fields) == "table" and meta.fields.ferment or 0
  if (ferment == 0) then
    ferment = random(300,360) -- base to return if error
    local ferment_data = ncrafting.get_ferment_data(name)
    if not ferment_data then return ferment end
    ferment = type(ferment_data.time) == "number" and ferment_data.time
      or type(ferment_data.time) == "table" and random(ferment_data.time.min,ferment_data.time.max) or ferment
  end
  return ferment
end

--set saved
function ncrafting.ferment_after_place(pos, placer, itemstack, pointed_thing)
	local meta = minetest.get_meta(pos)
	local stack_meta = itemstack:get_meta()
  stack_meta = stack_meta:to_table() or {fields={},inventory={}}
  stack_meta.fields.ferment = ncrafting.get_or_create_ferment(itemstack,stack_meta)
  meta:from_table(stack_meta)
end

function ncrafting.ferment_on_construct(pos)
  --duration of ferment
  local meta = minetest.get_meta(pos)
  meta:set_int("ferment", ncrafting.get_or_create_ferment(pos))
  --ferment
  minetest.get_node_timer(pos):start(ncrafting.ferment_interval)
end

-- custom function that preserves metadata from a replaced node to an itemstack
function ncrafting.ferment_preserve_metadata(pos, oldnode, oldmeta, transferred_stack)
  local imeta = transferred_stack:get_meta()
  oldmeta = oldmeta:to_table() or {fields={},inventory={}}
  oldmeta.fields.ferment = ncrafting.get_or_create_ferment(transferred_stack,oldmeta)
  imeta:from_table(oldmeta)
  --imeta:set_int("ferment",ncrafting.get_or_create_ferment(transferred_stack,imeta))
end

function ncrafting.ferment_on_timer(pos, elapsed)
  local ferment_data = ncrafting.get_ferment_data(pos)
  if not ferment_data then return false end
  local temp_range = ferment_data.temp_range
  local aerobic = ferment_data.aerobic
  if temp_range then
    --ferment if at right temp
    local temp = climate.get_point_temp(pos)
    if temp <= temp_range.min or temp >= temp_range.max then
      -- loop again if conditions not right
      return true
    end
  end
  if type(aerobic) == "boolean" then
    local air_node = minetest.registered_nodes[minetest.get_node(minimal.shift_pos(pos,{y=1})).name]
    if air_node.drawtype == "airlike" then
      -- anaerobic and air is above...
      if not aerobic then
        return true
      end
    elseif aerobic then
      -- aerobic, but no air above...
      return true
    end
  end
  -- only access meta if can ferment
  local meta = minetest.get_meta(pos)
  local ferment = meta:get_int("ferment")
  -- catchup included
  ferment = ferment - (elapsed >= (ncrafting.ferment_interval*2) and math.floor(elapsed/ncrafting.ferment_interval) or 1)
  if ferment <= 1 then -- prevent possibility of refreshed fermenting at 0
    local swap_def = minetest.registered_nodes[ferment_data.to]
    minetest.swap_node(pos, {name = ferment_data.to})
    minetest.get_meta(pos):set_int("ferment",0) -- end fermentation
    if type(swap_def.on_construct) == "function" then
      -- run on_construct function if available
      swap_def.on_construct(pos)
    end
    return false
  else
    meta:set_int("ferment",ferment)
  end
  return true
end
