minimal = minimal
S = minimal.S

function minimal.switch_node(pos, node, after_place)
   --Swap a node, but run its on_construct, so that
   -- timers etc. are started, but metadata is left intact

   -- after_place is to be a table of 3 parameters:
   -- placer, itemstack, pointed_thing - though does not need to be specified for switch_node to work
   local node_def = minetest.registered_nodes[node.name]
   if not node_def then
      minetest.log("error","Attempted to switch_node to an invalid node: "..node.name)
      return
   end
   minetest.swap_node(pos, node)
   if node_def.on_construct then
      node_def.on_construct(pos)
   end
  if (type(after_place) == "table") then
    if (node_def.after_place_node) then
      local placer = after_place[1]
      local itemstack = after_place[2]
      local pointed_thing = after_place[3]

      node_def.after_place_node(pos, placer, itemstack, pointed_thing)
    end
  end
end

function minimal.slabs_combine(player, itemstack, pointed_thing, swap_node)
   if not pointed_thing then return end -- Can't combine with nothing
   local pos = pointed_thing.under
   local node = minetest.get_node(pos)
   if itemstack:get_name() == node.name then
      -- combine slabs
      local stack_meta = itemstack:get_meta()
      if stack_meta:contains("fuel") then
	 local fuel = stack_meta:get_int("fuel")
	 local pt_meta = minetest.get_meta(pos)
	 fuel = fuel + pt_meta:get_int("fuel")
	 pt_meta:set_int("fuel",fuel)
      end
      minimal.switch_node(pos,{name=swap_node})
      itemstack:take_item()
      return true
   end
end

function minimal.slabs_split_hand(player, pointed_node, pointed_thing,
				  wielded_item)
   if not pointed_thing then return end -- Can't split from nothing
   if wielded_item:get_name() ~= "" then return end -- must be empty handed
   local nname = pointed_node.name
   local split_node = minetest.registered_nodes[nname]._splits_by_hand
   if not split_node then
      error("Tried to split a slab with no splits_by_hand defined! "..
	    pointed_node.name.." -- "..dump(split_node))
   end
   local pos = pointed_thing.under
   local meta = minetest.get_meta(pos)
   local itemstack = ItemStack(split_node)
   if meta:contains("fuel") then
      local fuel = meta:get_int("fuel") / 2
      meta:set_int("fuel", fuel)
      local imeta = itemstack:get_meta()
      imeta:set_int("fuel", fuel)
   end
   minimal.switch_node(pos, {name=split_node})
   wielded_item:replace(itemstack)
   return true
end

function minimal.get_nodedef(pos)
    local node_name = minetest.get_node(pos).name
    local nodedef = minetest.registered_nodes[node_name]
    return nodedef
end

function minimal.node_set_int(pos, name, value)
    local meta = minetest.get_meta(pos)
    meta:set_int(name, value)
end

function minimal.node_get_int(pos, name)
    local meta = minetest.get_meta(pos)
    if meta:get(name) then
        return meta:get_int(name)
    else
        return false
    end
end

function minimal.node_set_string(pos, name, value)
    local meta = minetest.get_meta(pos)
    meta:set_string(name, value)
end

function minimal.node_get_string(pos, name)
    local meta = minetest.get_meta(pos)
    if meta:get(name) then
        return meta:get_string(name)
    else
        return false
    end
end

function minimal.force_place(pos, node)
    minetest.remove_node(pos)
    minetest.set_node(pos, node)
end

function minimal.get_pos_under(pos)
    return {x = pos.x, y = pos.y - 1, z = pos.z}
end

function minimal.get_pos_above(pos)
    return {x = pos.x, y = pos.y + 1, z = pos.z}
end

function minimal.get_group(pos, group_name)
    local node_name = minetest.get_node(pos).name
    return minetest.get_item_group(node_name, group_name)
end

function minimal.get_param2(pos)
    local node = minetest.get_node(pos)
    return node.param2
end

function minimal.force_place_keep_param2(pos, name)
    local param2 = minimal.get_param2(pos)
    minimal.force_place(pos, {name = name, param2 = param2})
end
