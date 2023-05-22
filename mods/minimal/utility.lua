minimal = minimal

function minimal.switch_node(pos, node)
   --Swap a node, but run its on_construct, so that
   -- timers etc. are started, but metadata is left intact
   if not minetest.registered_nodes[node.name] then
      minetest.log("error","Attempted to switch_node to an invalid node: "..node.name)
      return
   end
   minetest.swap_node(pos, node)
   if minetest.registered_nodes[node.name].on_construct then
      minetest.registered_nodes[node.name].on_construct(pos)
   end
end

function minimal.safe_landing_spot(pos)
   if pos == nil then return false end
   local dest_top = minetest.get_node({ x = pos.x, y = pos.y+1, z = pos.z })
   local dest_bot = minetest.get_node({ x = pos.x, y = pos.y  , z = pos.z })
   local floor = vector.new( pos.x, pos.y-1, pos.z )
   local dest_flr = minetest.get_node(floor)
   local def_top = minetest.registered_nodes[dest_top.name]
   local def_bot = minetest.registered_nodes[dest_bot.name]
   local def_flr = minetest.registered_nodes[dest_flr.name]
   if dest_top.name ~= "ignore" and ( def_top and
				      def_top.walkable == true ) then
      return false -- loaded a solid node
   end
   if dest_bot.name ~= "ignore" and ( def_bot and
				      def_bot.walkable == true ) then
      return false
   end
   if dest_flr.name == "ignore" or ( def_flr and
				     def_flr.walkable == true ) then
      return true
   end
   -- floor is not walkable, search below it for a walkable floor
   local count = 0
   repeat
      floor = vector.add(floor, vector.new(0, -1, 0))
      dest_flr = minetest.get_node(floor)
      def_flr = minetest.registered_nodes[dest_flr.name]
      count = count + 1
   until ( def_flr and def_flr.walkable == true ) or
      count == 20
   if count == 20 then -- a 20 node drop is certain death
      return false
   else
      return true
   end
end

function minimal.invlists2string(lists)
   local cleantable = {}
   if not lists then return end
   for listname, list in pairs(lists) do
      cleantable[listname] = {}
      for i = 1, #list do
	 cleantable[listname][i] = list[i]:to_string()
      end
   end
   return minetest.serialize(cleantable)
end
function minimal.string2invlists(string)
   local table = minetest.deserialize(string)
   if not table then return end
   local newlist = {}
   for listname, list in pairs(table) do
      newlist[listname] = {}
      for i = 1, #list do
	 newlist[listname][i] = ItemStack(list[i])
      end
   end
   return newlist
end

-- Call in on_rightclick wrapper like this:
-- on_rightclick = function (pos, node, clicker, itemstack, pointed_thing)
--     return minimal.slabs_combine(pos,node,itemstack,'tech:large_wood_fire_ext')
-- end
function minimal.slabs_combine(pos, node, itemstack, swap_node)
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
		return itemstack
	end
end

local __click_count_ready = {}
function minimal.click_count_ready(name, id, pos, count, timeout)
	-- { playername_id = { timeout=time() + __timeout, count = __use_count } }
	local timeout = timeout or 2 -- 2 second window for timeout
	local count = count or 3 -- number of clicks
	local ready = __click_count_ready[name.."_"..id]
	if ready and ready.pos == pos then
		ready.count = ready.count + 1
		if os.time() < ready.timeout then
			if ready.count >= count then
				__click_count_ready[name.."_"..id]  = nil
				return true
			else
				return false
			end
		end
	end
	__click_count_ready[name.."_"..id] = {
		timeout = os.time() + timeout,
		count = 1,
		pos = pos,
	}
	return false
end

function minimal.sanitize_string(badstring)
   local disallowed = { "\\", "{", "}", "^", ";",
			--lua magic characters
			"%(", "%)", "%[", "%]", "%.", "%$",
			"%^", "%%", "%+", "%-", "%*", "%?"  }
   badstring:trim():lower()
   for i in ipairs(disallowed) do
      badstring = badstring:gsub(disallowed[i],"")
   end
   return badstring
end

-- merges content of t1 and t2 into a new table
-- if t1 and t2 contain identical keys, values from
-- t1 are overwritten with values from t2
function minimal.merge_tables(t1, t2)
    local new_table = table.copy(t1)
    --merge tables
    for key, value in pairs(t2) do
        new_table[key] = value
    end
    return new_table
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
