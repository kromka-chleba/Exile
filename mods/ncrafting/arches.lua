--------------------------------------------------------------------------
-- Arches
-- build a wall, knock out a doorway

local bit = bit

local function neigh(pos, axis, adj)
   local dir = vector.new()
   dir[axis] = adj
   local tpos = vector.add(pos, dir)

   return { pos = tpos, node = minetest.get_node(tpos), vector = dir }
end

local function get_cardinal_neighbors(pos, axis)
   return { neigh(pos, axis, -1),
	    neigh(pos, axis, 1) }
end

local basename -- the basic node name for the arch we're currently working with
local archname
local supportname
local function set_names(node)
   basename = node.name
   archname = node.name.."_arch"
   supportname = node.name.."_arch_support"
end

local supports = {} -- tracks which supports we've built, see below
local function on_construct_arch_support(pos)
   if supports[minetest.pos_to_string(pos)] then -- this is our node
      supports[minetest.pos_to_string(pos)] = nil -- we're done tracking it now
      return
   end
   -- Else: this node wasn't placed by us, so it was minetest falling code;
   --
   -- A workaround for the falling node being copied BEFORE on_destruct() is.
   -- Without this, supports may fail to revert to basename when they fall!
   local def = minetest.registered_nodes[minetest.get_node(pos).name]
   if def then
      minetest.swap_node(pos, { name = def.drop })
   end
end

local function create_arch_support(pos, p2)
   supports[minetest.pos_to_string(pos)] = true
   minetest.swap_node(pos, { name = supportname, param2 = p2 })
end

local function archable(node)
   if node.name == basename then
      return true -- true: can be made into an arch
   end
   if string.match(node.name, basename.."_arch") then
      return false -- false: is an arch or support already, check it
   end
end -- nil: all other nodes

local function fill_arch(nodetable, axis, mod)
   local center = nodetable[3].node
   center.param2 = mod + 1 -- center is 1 suspended node
   center.name = archname
   minetest.swap_node(nodetable[3].pos, center)
   create_arch_support(nodetable[1].pos, mod)
   create_arch_support(nodetable[2].pos, mod)
end

local function do_extend(support, arch, oldarch, mod)
   if bit.band(oldarch.node.param2, 2) == 2 then
      return -- reaches too far, just fall
   end
   arch.node.param2 = 2 + mod
   arch.node.name = archname
   minetest.swap_node(arch.pos, arch.node)
   oldarch.node.param2 = 2 + mod
   minetest.swap_node(oldarch.pos, oldarch.node)
   create_arch_support(support.pos, mod)
   return true -- extended an arch
end

local function check_for_arch(pos, node)
   local def = minetest.registered_nodes[node.name]
   if def and def.drop then node.name = def.drop end
   set_names(node) -- set the base name for all above functions
   local upos = vector.new(pos.x, pos.y + 1, pos.z)
   local upnode = minetest.get_node(upos)
   if not upnode or archable(upnode) == nil then return end -- fall like normal
   local middle = {pos = upos, node = upnode }
   for axis, mod in pairs({ ["x"] = 0, ["z"] = 128 }) do
      local ngb = get_cardinal_neighbors(upos, axis)
      local left = ngb[1]
      local right =  ngb[2]
      if archable(middle.node) == true then
	 if archable(left.node) == true and archable(right.node) == true then
	    fill_arch({ left, right, middle }, axis, mod)
	    return
	 end
      elseif archable(left.node) == true and archable(right.node) == false then
	 if do_extend(left, middle, right, mod) then
	    return
	 end
      elseif archable(left.node) == false and archable(right.node) == true then
	 if do_extend(right, middle, left, mod) then
	    return
	 end
      end
   end
end

local function drop_arch(ngb, plain_node)
   local dir = ngb.vector
   local pos = ngb.pos
   local count = 0
   local done = false
   repeat
      local node = minetest.get_node(pos)
      if node.name == plain_node or not node.name:match(plain_node) or done then
	 return
      end
      if node.name == supportname then done = true end -- don't go past supports
      count = count + 1
      minetest.swap_node(pos, { name = plain_node })
      pos = vector.add(pos, dir)
   until count > 5
end

local function remove_arches(pos)
   local oldnode = minetest.get_node(pos)
   local def = minetest.registered_nodes[oldnode.name]
   if not def or not def.drop then return end -- not a proper arch?
   for _, axis in ipairs({ "x", "z" }) do
	 local ngb = get_cardinal_neighbors(pos, axis)
	 drop_arch(ngb[1], def.drop)
	 drop_arch(ngb[2], def.drop)
   end
   -- minetest.swap_node(pos, { name = def.drop })
   -- ^ this does not work, see on_construct_arch_support() workaround
end

function ncrafting.register_arch(nodename)
   local adef = table.copy(minetest.registered_nodes[nodename])
   if not adef or not adef.groups or
      not adef.groups.falling_node or
      adef.after_dig_node or adef.on_destruct or adef.on_construct
   then
      error("Tried to register an invalid arch material: ",nodename)
   end
   minetest.override_item(nodename, { after_dig_node = check_for_arch } )
   adef.on_destruct = remove_arches
   adef.drop = nodename
   adef.after_dig_node = check_for_arch
   adef.groups["not_in_creative_inventory"] = 1
   local sdef = table.copy(adef)
   adef.groups.falling_node = nil -- disable on arch, not support
   minetest.register_node(nodename.."_arch", adef)
   sdef.on_construct = on_construct_arch_support
   minetest.register_node(nodename.."_arch_support", sdef)
end
