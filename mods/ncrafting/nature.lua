local function is_pos(pos)
  if (type(pos) == "table") then
    if (type(pos.x) == "number" and type(pos.y) == "number" and type(pos.z) == "number") then
      return true
    end
  end
  return false
end

local function get_soil_pos(pos)
  local node = minetest.get_node(pos)
  if (minimal.in_group(node,"flora") or minimal.in_group(node,"seed")) then
    pos.y = pos.y - 1
    node = minetest.get_node(pos)
    if minimal.in_group(node,"sediment") then
      return pos
    end
  elseif (minimal.in_group(node,"sediment")) then
    return pos
  end
  
  return
end

-- allow players to salt the earth!!! muhahahahaha
local function get_salty(name)
  local salty_name
  local ndef = minetest.registered_nodes[name]
  if (ndef and type(ndef._wet_salty_name) == "string") then
    -- remove and then readd mod_origin from the name
    local mod_origin = ndef.mod_origin..":"
    -- get shape to get proper returned node
    local shape = string.match(name,"slope_inner_") or string.match(name,"slope_outer_") or string.match(name,"slope_pike_") or string.match(name,"slope_")
    if not shape then
      shape = ""
    end
    salty_name = mod_origin..shape..string.gsub(ndef._wet_salty_name,mod_origin,"")
  end
  return salty_name
end

local function wet_soil(pos, suffix)
  if not is_pos(pos) then
    return
  end
  local node = minetest.get_node(pos)
  if (type(suffix) ~= "string") then
    suffix = ""
  end
  if (suffix ~= "" and string.sub(suffix,1,1) ~= "_") then
    -- add underscore if not found
    suffix = "_"..suffix
  end
  suffix = "_wet"..suffix
  
  -- check if watered block exists
  local wet_node_name = node.name .. suffix
  -- Check if the players can... salt the Earth!!! (if they have a salty watering can)
  if string.match(suffix,"salty") then
    wet_node_name = get_salty(node.name)
    if not wet_node_name then
      -- normalize
      wet_node_name = node.name .. suffix
    end
  end
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

function ncrafting.water_soil(itemstack, user, pointed_thing, water_source,
			  empty_container, node_suffix)
  -- can only water nodes
  assert(type(empty_container) == "string","ncrafting.water_soil: string expected for empty_container, got: "..type(empty_container))
  assert(type(water_source) == "string","ncrafting.water_soil: string expected for water_source, got: "..type(water_source))
  assert(type(pointed_thing) == "table","ncrafting.water_soil: provided pointed_thing is not a table! got: "..type(pointed_thing))
  if (pointed_thing.type == "node"
    and itemstack) then
    local pos = get_soil_pos(pointed_thing.under) -- will only return a pos if a soil is found
    if (is_pos(pos) and wet_soil(pos, node_suffix)) then
      -- if position is good and can wet the soil
      -- check if player is in creative
      if minimal.player_in_creative(user) then
        return
      end
      -- if not in creative, empty the can out
      itemstack:take_item()
      return ItemStack(empty_container)
    end
  end
  
  -- continue as normal (with a twist)
  return liquid_store.on_use_filled_bucket(
    water_source, empty_container,
    itemstack, user, pointed_thing, false)
end

function ncrafting.fertilize(pos, puncher, itemstack)
  assert(is_pos(pos),"ncrafting.fertilize: provided position is not a position!")
  local inv
  local replace_with = ""
  if minetest.is_player(puncher) and not itemstack then
    itemstack = puncher:get_wielded_item()
    inv = puncher:get_inventory()
  end
  
  local ndef = minimal.get_nodedef(pos)
  if type(ndef._fertilize_replace_with) == "string" then
    replace_with = ndef._fertilize_replace_with
  end
  
  -- avoid having to set up a "fertilized" boolean to prevent another check over
  local function complete()
    replace_with = ItemStack(replace_with)
    
    if inv then
      inv:remove_item("main",itemstack)
      inv:add_item("main",replace_with)
    else
      -- no inventory found
      if (itemstack:get_count() > 1) then
        itemstack:take_item()
        -- no inventory to place into
        minetest.item_drop(itemstack, puncher, pos)
      end
    end
    return replace_with
  end
  
  if (minimal.in_group(replace_with,"compost") and type(ndef._fertile_name) == "string") then
    if not minetest.registered_nodes[ndef._fertilize_name] then
      minetest.log("error","ncrafting: '"..ndef._fertilize_name.."' is not a valid item/node!")
      return itemstack
    end
    minetest.swap_node(pos, {name = ndef._fertilize_name})
    return complete()
  end
  
  if (minimal.in_group(replace_with,"fertilizer") and type(ndef._rich_name) == "string") then
    if not minetest.registered_nodes[ndef._rich_name] then
      minetest.log("error","ncrafting: '"..ndef._rich_name.."' is not a valid item/node!")
      return itemstack
    end
    minetest.swap_node(pos, {name = ndef._rich_name})
    return complete()
  end
  
  return itemstack
end