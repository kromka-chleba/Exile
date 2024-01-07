ncrafting = ncrafting

local function get_soil_pos(pos)
  local node = minetest.get_node(pos)
  if (minimal.in_group(node,"flora") or minimal.in_group(node,"seed")) then
    pos.y = pos.y - 1
    node = minetest.get_node(pos)
  end
  if minimal.in_group(node,"sediment") then
    return pos
  -- permit interactions with compost
  elseif minetest.get_item_group(node.name,"compost") == 1 or minetest.get_item_group(node.name,"undecomposed_compost") == 1 then
    return pos
  end
  return
end

-- provides "wet" as a suffix already, so that all that needs to be applied
-- is either nothing or "salty" to get "wet_salty"
-- may remove this in the future if different liquids exist
local function wet_soil(pos, suffix)
  if not vector.check(pos) then
    return
  end
  local node = minetest.get_node(pos)
  if (type(suffix) ~= "string") then
    suffix = ""
  else
    -- lowercase it :D
    suffix = string.lower(suffix)
  end
  if (suffix ~= "" and string.sub(suffix,1,1) ~= "_") then
    -- add underscore if not found
    suffix = "_"..suffix
  end
  if (suffix == "_wet") then
    -- we define it later on, clear it
    suffix = ""
  end
  suffix = "_wet"..suffix

  -- check if watered block exists
  local wet_node_name = node.name .. suffix
  -- otherwise do normal checking
  if not minetest.registered_nodes[wet_node_name] and
    string.match(node.name,"depleted") then
    -- depleted nodes with roots have "depleted" behind the "roots", so
    --  I declare this if statement first
    -- IF the provided node is "depleted", look for its proper depleted
    --  wet variant
    wet_node_name = string.gsub(wet_node_name,"_depleted","")
    wet_node_name = wet_node_name.."_depleted"
    -- we didn't erase "_wet" from the name
  end
  if not minetest.registered_nodes[wet_node_name]
    and string.match(node.name,"roots") then
    -- IF the provided node is "roots", look for its proper roots
    --  wet variant
    wet_node_name = string.gsub(wet_node_name,"_roots","")
    wet_node_name = wet_node_name.."_roots"
    -- we didn't erase "_wet" from the name
  end

  if minetest.registered_nodes[wet_node_name] then
    -- replace with watered version
    -- keeping the node orientation
    minetest.set_node(pos, {name = wet_node_name, param2 = node.param2})
    return true
  end

  return false
end

-- water soil with a watering can
function ncrafting.water_soil(itemstack, user, pointed_thing, node_suffix, empty_container)
  -- will apply "_wet" before node_suffix unless it is "_wet"
  -- empty_container can be an override, otherwise specified in storeddef
  assert(type(pointed_thing) == "table","ncrafting.water_soil: provided pointed_thing is not a table! got: "..
	  type(pointed_thing))
  if not empty_container then
    local storeddef = liquid_store.get_sl_def(itemstack:get_name())
    empty_container = storeddef and storeddef.nodename_empty
  end
  assert(type(empty_container) == "string","ncrafting.water_soil: string expected for empty_container, got: "..
	  type(empty_container))

  -- can only water nodes
  if (pointed_thing.type == "node"
    and itemstack) then
    local pos = get_soil_pos(pointed_thing.under) -- will only return a pos if a soil is found
    if (vector.check(pos) and wet_soil(pos, node_suffix)) then
      -- if position is good and can wet the soil
      -- check if player is in creative
      if minimal.player_in_creative(user) then
        return
      end
      -- if not in creative, empty the can out
      itemstack:take_item()
      return ItemStack(empty_container), true
    end
  end

  -- continue as normal (with a twist)
  return liquid_store.on_use_filled_bucket(itemstack, user, pointed_thing, false)
end

-- fertilize soil with a fertilizer
function ncrafting.fertilize(pos, puncher, itemstack)
  assert(vector.check(pos),"ncrafting.fertilize: provided position is not a position!")
  local inv
  local replace_with = ""
  if minetest.is_player(puncher) then
    inv = puncher:get_inventory()
    if not itemstack then
      itemstack = puncher:get_wielded_item()
    end
  end
  if not itemstack or itemstack:get_name() == "" then
    -- no itemstack, or have a hand? NO FERTILIZATION!
    return
  end

  pos = get_soil_pos(pos)
  if not pos then
    return
  end
  local ndef = minimal.get_nodedef(pos)
  local itemdef = minimal.get_nodedef(itemstack:get_name())
  if not (ndef and itemdef) then
    -- definition don't exist
    return
  end

  -- find all possible variations of a replaceable
  if type(itemdef._fertilize_replace_with) == "string" then
    replace_with = itemdef._fertilize_replace_with
  elseif type(itemdef.fertilize_replace_with) == "string" then
    replace_with = itemdef.fertilize_replace_with
  else
    local slab = string.gsub(itemstack:get_name(),ndef.mod_origin..":","")
    slab = "stairs:slab_"..slab
    if minetest.registered_nodes[slab] then
      replace_with = slab
    end
  end
  -- convert to itemstack
  replace_with = ItemStack(replace_with)

  -- avoid having to set up a "fertilized" boolean to prevent another check over
  local function complete()
    -- allow a custom "after_fertilize" function
    if type(itemdef._after_fertilize) == "function" then
      return itemdef._after_fertilize(pos, itemstack, puncher)
    end
    -- proceed as usual
    if not replace_with then
      -- if replace_with somehow broke, ensure no error
      replace_with = ItemStack('')
    end
    itemstack:take_item()
    if inv then
      if itemstack:get_count() <= 0 then
        inv:remove_item("main",itemstack)
      end
      if inv:room_for_item("main",replace_with) then
        inv:add_item("main",replace_with)
      else
        minetest.item_drop(replace_with, puncher, pos)
      end
    else
      -- no inventory found
      if (itemstack:get_count() > 0) then
        itemstack:take_item()
      end
      -- no inventory to place into
      minetest.item_drop(itemstack, puncher, pos)
    end
    return itemstack, replace_with, true -- give a third parameter telling the function that it went well
  end

  -- find fertilizing/composting
  local node_name = ndef._fertile_name
  if node_name == ndef.name then
    -- prevent the ability to fertilize something already fertilized lol
    return itemstack
  end
  if (minimal.in_group(itemdef,"compost") and type(node_name) == "string") then
    if not minetest.registered_nodes[node_name] then
      minetest.log("error","ncrafting: '"..node_name.."' is not a valid item/node!")
      return itemstack
    end
    minetest.swap_node(pos, {name = node_name})
    return complete()
  end

  -- find enriching
  node_name = ndef._rich_name
  if node_name == ndef.name then
    -- prevent the ability to enrich something already enriched lol
    return itemstack
  end
  if (minimal.in_group(itemdef,"fertilizer") and type(node_name) == "string") then
    if not minetest.registered_nodes[node_name] then
      minetest.log("error","ncrafting: '"..node_name.."' is not a valid item/node!")
      return itemstack
    end
    minetest.swap_node(pos, {name = node_name})
    return complete()
  end

  return itemstack
end
