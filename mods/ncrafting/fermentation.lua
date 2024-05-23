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
  return {
    to = def._ferment_to,
    time = def._ferment_time or {min=300,max=360},
    temp_range = def._ferment_temp_range
  }
end

-- find ferment or create a ferment meta
function ncrafting.get_or_create_ferment(name,meta)
  local ferment = type(meta) == "userdata" and meta:get_int("ferment") or 0
  if (ferment == 0) then
    ferment = math.random(300,360) -- base to return if error
    local ferment_data = ncrafting.get_ferment_data(name)
    if not ferment_data then return ferment end
    ferment = type(ferment_data.time) == "number" and ferment_data.time
      or type(ferment_data.time) == "table" and math.random(ferment_data.time.min,ferment_data.time.max) or ferment
  end
  return ferment
end

--set saved
function ncrafting.ferment_after_place(pos, placer, itemstack, pointed_thing)
	local meta = minetest.get_meta(pos)
	local stack_meta = itemstack:get_meta()
	local ferment = ncrafting.get_or_create_ferment(itemstack,stack_meta)
	if ferment >0 then
		meta:set_int("ferment", ferment)
	end
end

function ncrafting.ferment_on_construct(pos)
  --duration of ferment
  local meta = minetest.get_meta(pos)
  meta:set_int("ferment", ncrafting.get_or_create_ferment(pos))
  --ferment
  minetest.get_node_timer(pos):start(ferment_interval)
end

-- custom function that preserves metadata from a replaced node to an itemstack
function ncrafting.ferment_preserve_metadata(pos, oldnode, oldmeta, transferred_stack)
  local imeta = transferred_stack:get_meta()
  imeta:set_int("ferment",ncrafting.get_or_create_ferment(transferred_stack,oldmeta))
end

function ncrafting.ferment_on_timer(pos, elapsed)
  local ferment_data = ncrafting.get_ferment_data(pos)
  if not ferment_data then return false end
  local can_ferment = true
  local temp_range = ferment_data.temp_range
  if temp_range then
    --ferment if at right temp
    local temp = climate.get_point_temp(pos)
    if temp >= temp_range.min and temp <= temp_range.max then
      can_ferment = true
    else
      can_ferment = false
    end
  end
  if not can_ferment then return true end
  -- only access meta if can ferment
  local meta = minetest.get_meta(pos)
  local ferment = meta:get_int("ferment")
  -- catchup included
  ferment = ferment - (elapsed >= (ncrafting.ferment_interval*2) and math.floor(elapsed/ncrafting.ferment_interval) or 1)
  if ferment <= 1 then -- prevent possibility of refreshed fermenting at 0
    minetest.swap_node(pos, {name = ferment_data.to})
    return false
  else
    meta:set_int("ferment",ferment)
  end
  return true
end
