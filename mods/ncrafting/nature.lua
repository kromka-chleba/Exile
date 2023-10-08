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
  if not minimal.in_group(node,"sediment") then
    return
  end
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
  -- if no wet version could be found, check if the players can... salt the Earth!!!
  if not minetest.registered_nodes[wet_node_name] and string.match(suffix,"salty") then
     wet_node_name = get_salty(node.name)
  end
  if wet_node_name and minetest.registered_nodes[wet_node_name] then
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
  if (pointed_thing.type == "node"
    and itemstack
    and type(pointed_thing) == "table") then
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