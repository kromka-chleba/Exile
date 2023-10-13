minimal = minimal
wielded_light = wielded_light
S = minimal.S

-- check if a valid meta was given
local function is_meta(meta)
  if (type(meta) == "userdata") then
    -- ensure it has these 2 functions lol
    if (type(meta["set_int"]) == "function" and type(meta["set_string"]) == "function") then
      return true
    end
  end

  return false
end

-- check if a valid pos was given
local function is_pos(pos)
  if (type(pos) == "table") then
    if (type(pos.x) == "number" and type(pos.y) == "number" and type(pos.z) == "number") then
      return true
    end
  end

  return false
end

function minimal.switch_node(pos, node, after_place)
   --Swap a node, but run its on_construct, so that
   -- timers etc. are started, but metadata is left intact

   -- after_place is to be a table of 3 parameters:
   -- placer, itemstack, pointed_thing - though does not need to be specified for switch_node to work
   assert(is_pos(pos), "exile_game.switch_node: Invalid pos given")
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

function minimal.node_set_int(pos, name, value)
  assert(type(value) == "number","exile_game.node_set_int: Invalid value given, expected number got "..type(value))
  local meta
  if (is_meta(pos)) then
    meta = pos
  elseif (is_pos(pos)) then
    meta = minetest.get_meta(pos)
  else
    error("exile_game.node_set_int: Invalid pos given")
  end

  meta:set_int(name, value)
end

function minimal.node_get_int(pos, name)
  local meta
  if (is_meta(pos)) then
    meta = pos
  elseif (is_pos(pos)) then
    meta = minetest.get_meta(pos)
  else
    error("exile_game.node_get_int: Invalid pos given")
  end
  if meta:get(name) then
    return meta:get_int(name)
  end

  return false
end

function minimal.node_set_string(pos, name, value)
  assert(type(value) == "string","exile_game.node_set_string: Invalid value given, expected string got "..type(value))
  local meta
  if (is_meta(pos)) then
    meta = pos
  elseif (is_pos(pos)) then
    meta = minetest.get_meta(pos)
  else
    error("exile_game.node_set_string: Invalid pos given")
  end

  meta:set_string(name, value)
end

function minimal.node_get_string(pos, name)
  local meta
  if (is_meta(pos)) then
    meta = pos
  elseif (is_pos(pos)) then
    meta = minetest.get_meta(pos)
  else
    error("exile_game.node_get_string: Invalid pos given")
  end
  if meta:get(name) then
    return meta:get_string(name)
  else
    return false
  end
end

function minimal.force_place(pos, node)
  assert(is_pos(pos),"exile_game.force_place: Invalid pos given")
  minetest.remove_node(pos)
  minetest.set_node(pos, node)
end

-- inspired by mobkit's "pos_shift"
-- can have x, y, z of pos2 be omitted
function minimal.shift_pos(pos,pos2)
  -- simple error messages to make debugging easier
  assert( is_pos(pos),"exile_game.shift_pos: Invalid pos provided (not a table or missing coodinates)")
  assert( type(pos2) == "table","exile_game.shift_pos: Invalid pos2 provided (not a table or missing coodinates)")

  -- make certain they're 0 and not nil if nil
  pos2.x = pos2.x or 0
  pos2.y = pos2.y or 0
  pos2.z = pos2.z or 0

  local n_pos = { -- new pos
    x = pos.x + pos2.x,
    y = pos.y + pos2.y,
    z = pos.z + pos2.z,
  }

  return n_pos
end
-- alias of "minimal.shift_pos"
function minimal.pos_shift(...)
  return minimal.shift_pos(...)
end

function minimal.get_pos_under(pos)
    return {x = pos.x, y = pos.y - 1, z = pos.z}
end

function minimal.get_pos_above(pos)
    return {x = pos.x, y = pos.y + 1, z = pos.z}
end

local function get_node_name(pos)
  local node_name
  if is_pos(pos) then
    node_name = minetest.get_node(pos).name
  elseif (type(pos) == "table" and type(pos.name) == "string") then
    node_name = pos.name
  elseif type(pos) == "string" then
    node_name = pos
  elseif (type(pos) == "userdata") then
    -- also handle getting groups of itemstacks :D
    if (type(pos["get_name"]) == "function") then
      node_name = pos:get_name()
    end
  end
  return node_name
end

function minimal.get_nodedef(pos)
  local node_name = get_node_name(pos)
  if not node_name then
    -- got nothing, return nothing
    return
  end
  local nodedef = minetest.registered_nodes[node_name]
  return nodedef
end

function minimal.in_group(pos, group_name)
  local node_name = get_node_name(pos)
  assert(type(node_name) == "string",
	 "exile_game.in_group: Invalid pos or name provided for node, got "..
	 type(node_name))
  assert(type(group_name) == "string",
	 "exile_game.in_group: Invalid group_name provided, got "..
	 type(group_name))
  local group_val = minetest.get_item_group(node_name,group_name)
  if (group_val > 0) then
    return group_val
  end
  return false
end

function minimal.safe_landing_spot(pos)
   if not is_pos(pos) then return false end
   local floor = vector.new( pos.x, pos.y-1, pos.z )
   local def_top = minimal.get_nodedef(minimal.shift_pos(pos,{y = 1}))
   local def_bot = minimal.get_nodedef(pos)
   local def_flr = minimal.get_nodedef(floor)
   if def_top.name ~= "ignore" and ( def_top and
				      def_top.walkable == true ) then
      return false -- loaded a solid node
   end
   if def_bot.name ~= "ignore" and ( def_bot and
				      def_bot.walkable == true ) then
      return false
   end
   if def_flr.name == "ignore" or ( def_flr and
				     def_flr.walkable == true ) then
      return true
   end
   -- floor is not walkable, search below it for a walkable floor
   for i = 0, 20 do
     floor = minimal.shift_pos(floor,{y = -1})
     def_flr = minimal.get_nodedef(floor)
     if (def_flr and def_flr.walkable == true) then
       return true
     end
   end
   -- if got to end of loop, then a 20 node drop is certain death
   return false
end

function minimal.get_param2(pos)
  assert(is_pos(pos),"exile_game.get_param2: Invalid pos given")
  local node = minetest.get_node(pos)
  return node.param2
end

function minimal.force_place_keep_param2(pos, name)
  assert(is_pos(pos),"exile_game.force_place_keep_param2: Invalid pos given")
  local param2 = minimal.get_param2(pos)
  minimal.force_place(pos, {name = name, param2 = param2})
end

-- will handle converting on_place functionality into on_rightclick (returns given itemstack or nil)
-- USE minimal.on_rightclick_possible to VERIFY if this function should be ran
function minimal.on_rightclick(itemstack, user, pointed_thing, aboveorunder)
  -- seek under or above (anything not true is under, true is above)
  if aboveorunder ~= true then
    aboveorunder = false
  end
  if not (minetest.is_player(user) and itemstack and type(pointed_thing) == "table") then
    return false
  end
  local pos = pointed_thing.under
  if aboveorunder then
    pos = pointed_thing.above
  end
  if not is_pos(pos) then
    return false
  end

  local nodedef = minimal.get_nodedef(pos)

  if not nodedef then
    return false
  end

  -- can rightclick
  if nodedef.on_rightclick then
    local node = minetest.get_node(pos)
    return nodedef.on_rightclick(pos, node, user, itemstack, pointed_thing)
  end
  -- can't rightclick
  return false
end

function minimal.dig_up(pos, node, digger)
	if digger == nil then return end
	local lnode = wielded_light.get_unlit_node(node)
	local np = vector.new(pos.x,pos.y,pos.z)
	local unode = wielded_light.get_unlit_node(minetest.get_node(np))
	local count = 0
	local removetable = {}
	while lnode.name == unode.name do
	   count = count + 1
	   table.insert(removetable, vector.new(np.x, np.y, np.z))
	   np.y = np.y + 1
	   unode = wielded_light.get_unlit_node(minetest.get_node(np))
	end
	if count > 0 then
	   local inv = digger:get_inventory()
	   if inv:room_for_item("main", lnode.name.." "..tostring(count)) then
	      inv:add_item('main', lnode.name.." "..tostring(count))
	      for i = 1, #removetable do
		 minetest.set_node(removetable[i], {name = "air"})
	      end
	      return true
	   else
	      minimal.warn_inv_full(digger)
	   end
	end
	return false
end
