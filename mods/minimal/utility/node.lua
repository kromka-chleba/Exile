minimal = minimal
wielded_light = wielded_light
local S = minimal.S

-- check if a valid meta was given
function minimal.is_meta(meta)
    -- meta is userdata and nothin else
    if type(meta) ~= "userdata" then return false end
    -- all meta have set_int and set_string
    if type(meta.set_int) ~= "function" or type(meta.set_string) ~= "function" then return false end
    -- we're meta
    return true
end
local is_meta = minimal.is_meta

-- swap a node, but run its on_construct, so that
-- timers etc are started, but metadata is left intact
-- node argument can be string, will be set as the "name"

-- after_place is optional but if provided, expected to be a table of 3 parameters
-- placer (player), itemstack (or itemstack being wielded by player, will be grabbed from player if not provided),
-- and 3rd, pointed_thing table
function minimal.switch_node(pos, node, after_place)
    assert(vector.check(pos), "exile_game.switch_node: Invalid pos given")
    -- permit string argument for node
    node = type(node) == "string" and {name = node} or node
    assert(type(node) == "table",
      "exile_game.switch_node: invalid argument for node - not a string for name or get_node table")
    assert(type(node.name) == "string", "exile_game.switch_node: invalid argument for node.name - not a string")
    local ndef = core.registered_nodes[node.name]
    if not ndef then
        error("exile_game.switch_node: attempted to switch to an invalid node "..node.name)
    end
    minetest.swap_node(pos, node)
    if ndef.on_construct then
        ndef.on_construct(pos)
    end
    -- after place option provided
    if type(after_place) == "table" and type(ndef.after_place_node) == "function" then
        local player, itemstack = after_place[1], after_place[2]
        if not core.is_player(player) then return end -- invalid placer argument, not a player
        -- get wielded item if itemstack not provided
        itemstack = type(itemstack) == "userdata" and itemstack or player:get_wielded_item()
        -- placer, itemstack, pointed_thing
        ndef.after_place_node(pos, player, itemstack, after_place[3])
    end
end

function minimal.slabs_combine(player, itemstack, pointed_thing, swap_node)
    if not pointed_thing or pointed_thing.type ~= "node" then return end
    -- Can't combine with nothing, or with objects
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

function minimal.node_set_int(pos_or_meta, name, value)
    if type(value) ~= "number" then
             error( "exile_game.node_set_int: Invalid value given, expected "..
                    "number got ".. type(value))
    end
    -- meta argument or pos
    local meta = is_meta(pos_or_meta) and pos_or_meta or vector.check(pos_or_meta) and core.get_meta(pos_or_meta)
    if not meta then
        error("exile_game.node_set_int: invalid pos or meta given")
    end

    meta:set_int(name, value)
end

function minimal.node_get_int(pos_or_meta, name)
    -- meta userdata or pos vector
    local meta = is_meta(pos_or_meta) and pos_or_meta or vector.check(pos_or_meta) and core.get_meta(pos_or_meta)
    if not meta then
        error("exile_game.node_get_int: invalid pos or meta given")
    end
    if meta:get(name) then
        return meta:get_int(name)
    end
    return false
end

function minimal.node_set_string(pos_or_meta, name, value)
    if  type(value) ~= "string" then
        error("exile_game.node_set_string: "..
              "Invalid value given, expected string got "..type(value) )
    end
    -- meta userdata or pos vector
    local meta = is_meta(pos_or_meta) and pos_or_meta or vector.check(pos_or_meta) and core.get_meta(pos_or_meta)
    if not meta then
        error("exile_game.node_set_string: invalid pos or meta given")
    end

    meta:set_string(name, value)
end

function minimal.node_get_string(pos_or_meta, name)
    -- meta userdata or pos vector
    local meta = is_meta(pos_or_meta) and pos_or_meta or vector.check(pos_or_meta) and core.get_meta(pos_or_meta)
    if not meta then
        error("exile_game.node_get_string: invalid pos or meta given")
    end
    if meta:get(name) then
        return meta:get_string(name)
    end
    return false
end

function minimal.force_place(pos, node)
    assert(vector.check(pos),"exile_game.force_place: Invalid pos given")
    minetest.remove_node(pos)
    minetest.set_node(pos, node)
end

function minimal.shift_pos(pos,change)
    -- Get a position relative to pos, like vector.new(pos,x + change.x, ...)
    -- change is a table with keys of x, y, and/or z, like: { y = 1, z = -3 }

    if not vector.check(pos) then
        print("invalid pos: ",dump(pos))
    end
    assert( vector.check(pos),
            "exile_game.shift_pos: Invalid pos provided ")
    assert( type(change) == "table",
            "exile_game.shift_pos: Invalid change provided")


    local new_pos = vector.new(pos.x + ( change.x or 0 ),
        pos.y + ( change.y or 0 ),
        pos.z + ( change.z or 0 )
    )

    return new_pos
end
-- alias of "minimal.shift_pos"
function minimal.pos_shift(...)
    return minimal.shift_pos(...)
end

function minimal.get_pos_under(pos)
    return vector.new(pos.x, pos.y - 1, pos.z)
end

function minimal.get_pos_above(pos)
    return vector.new(pos.x, pos.y + 1, pos.z)
end

function minimal.get_nodedef(pos)
    local node_name = minetest.get_node(pos).name
    if not node_name then
        -- got nothing, return nothing
        return
    end
    local nodedef = minetest.registered_nodes[node_name]
    return nodedef
end

function minimal.pos_group(pos, group_name)
    if not vector.check(pos) then
        if type(pos) == "table" and pos.x then
            print("pos_group: deprecated pos table use")
            print(debug.traceback())
        else error("pos_group: invalid pos") end
    end
    local node_name = minetest.get_node(pos).name
    local group_val = minetest.get_item_group(node_name, group_name)
    if group_val > 0 then return group_val end
end

function minimal.safe_landing_spot(pos)
    if not vector.check(pos) then return false end
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
    assert(vector.check(pos),"exile_game.get_param2: Invalid pos given")
    local node = minetest.get_node(pos)
    return node.param2
end

function minimal.force_place_keep_param2(pos, name)
    assert(vector.check(pos),"exile_game.force_place_keep_param2: Invalid pos given")
    local param2 = minimal.get_param2(pos)
    minimal.force_place(pos, {name = name, param2 = param2})
end

-- will handle converting on_place functionality into on_rightclick
--   (returns given itemstack or nil)
-- USE minimal.on_rightclick_possible to VERIFY if this function should be ran
function minimal.on_rightclick(itemstack, user, pointed_thing, aboveorunder)
    -- seek under or above (anything not true is under, true is above)
    if aboveorunder ~= true then
        aboveorunder = false
    end
    if not (minetest.is_player(user) and itemstack
            and type(pointed_thing) == "table") then
        return false
    end
    local pos = pointed_thing.under
    if aboveorunder then
        pos = pointed_thing.above
    end
    if not vector.check(pos) then
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
    if digger == nil or not minetest.is_player(digger) then return end
    -- #TODO: allow animals to dig cane plants?
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
            if minetest.item_pickup then
                minetest.item_pickup(ItemStack(lnode.name.." "..
                                               tostring(count)),
                                     digger)
            else
                inv:add_item('main', lnode.name.." "..tostring(count))
            end
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

-- expects pointed_thing, but will return a proper position if provided one
-- basically core.get_pointed_thing_position but permits throwing a pos into it
function minimal.get_usable_position(pt, ...)
    if type(pt) ~= "table" then return end -- not a table
    if vector.check(pt) then return pt end -- is a position
    if pt.x and pt.y and pt.z then return vector.new(pt.x, pt.y, pt.z) end -- also a position but table'd
    -- now off to our friend
    return core.get_pointed_thing_position(pt, ...)
end