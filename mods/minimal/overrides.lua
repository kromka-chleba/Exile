--overrides.lua
--Alters base minetest functions for:
--item_place
--is_protected
--fall damage

minetest = minetest
core = core

local fall_damage_multiplier = 1.5

local S = minimal.S

minetest.override_item("air", { groups = { air = 1,
                                           not_in_creative_inventory = 1} })

-- check for/do on_rightclick() of pointed_thing,
-- required for our minetest.item_place() and
-- for items with a custom on_place() which does not use minetest.item_place()
function minimal.pointed_thing_on_rightclick(itemstack, placer, pointed_thing)
    if pointed_thing.type == "node" and minetest.is_player(placer) then
        local ndef = minimal.get_nodedef( pointed_thing.under )

        if ndef and (ndef.override_sneak == true
                     or not placer:get_player_control().sneak) then
            local on_click = minimal.on_rightclick(itemstack, placer,
                                                   pointed_thing)
            if on_click ~= false then
                return on_click or itemstack
            end
        end
    end
    -- case not yet handled or on_rightclick() allowed more to be done
    return false
end

-- fool-proof approach to avoid circular dependency with crafting
local craft_ground_on_rightclick = nil
function minimal.set_crafting_ground_on_rightclick(func)
    craft_ground_on_rightclick = function (pos, tool_node, clicker,
                                           empty_stack, pointed_thing)
        func(pos, tool_node, clicker, empty_stack, pointed_thing)
    end
end

-- Helper for minetest.item_place
-- Opens crafting when the player pointed on top of a node of group
-- 'craft_ground' (while excluding stairs and slopes), if air is above that
-- node and the node is within a range of 2.8.
-- returns: false if conditions are not met or true otherwise
local hand_on_rightclick = function(clicker, pointed_thing)
    if not minetest.is_player(clicker) or not pointed_thing
        or pointed_thing.type ~= "node" then

        return false
    end

    -- position invalid?
    local under = pointed_thing.under
    if not vector.check(under) then return false end

    -- ground not appropriate?
    local node = core.get_node(under)
    if not node.name
        or (core.get_item_group(node.name, "craft_ground") == 0)
        or (core.get_item_group(node.name, "stair") > 0)
        or (core.get_item_group(node.name, "natural_slope") > 0) then

        return false
    end
    -- not slabs with inappropriate orientation?
    if (core.get_item_group(node.name, "slab") > 0)
        and (node.param2 > 3) and (node.param2 < 20) then

        return false
    end

    -- no space to sit on top/in front of pointed face?
    local above = pointed_thing.above
    if not vector.check(above) or not minimal.pos_group(above, "air") then
        return false
    end

    -- not pointed onto top of a node?
    if vector.direction(above, under).y ~= -1 then return false end

    -- to far? (allow from within beds but not on other side of a canyon)
    if vector.distance(clicker:get_pos(), under) > 2.8 then
        local player_name = clicker:get_player_name()
        minimal.send_message(clicker, player_name, S("Too far away!"), 1)
        core.sound_play("failure", {to_player = player_name}, true)
        return false
    end

    -- ground supports crafting? -> open station with nil as tool name
    if not craft_ground_on_rightclick then return false end
    local tool_node = {}
    craft_ground_on_rightclick(under, tool_node, clicker,
                               ItemStack(), pointed_thing)
    return true
end


----- Running mean -----

-- `running_mean`: Defines a class to work with running means based on up to
--     `base_count` values (see new(base_count))
local running_mean = {}

-- `running_mean:include(value)`: Includes `value` into the calculation,
--     replacing the oldest value, if there were already `base_count` values
--     included.
function running_mean:include(value)
    if self.count then
        local drop_value = self.values[self.next_store]
        if drop_Value then
            self.total = self.total - self.values[self.next_store]
            self.count = self.count - 1
        end
    end
    self.values[self.next_store] = value
    self.next_store = self.next_store % self.base_count + 1
    self.total = self.total + value
    self.count = self.count + 1
end

-- `running_mean:mean()`: Returns the average of all currently included values
--     or 0 if there are no values.
function running_mean:mean()
    if self.count == 0 then return 0 end
    return self.total / self.count;
end

-- `running_mean:mean`: Constructs a new object to calculate the running mean
--     of up to `base_count` included values.
-- `base_count`: max. number of values to consider; must be a number or nil;
--     default: 5
function running_mean:new(base_count)
    local instance = {
        include = self.include,
        mean = self.mean,
        values ={},
        next_store = 1,
        total = 0,
        count = 0,
        base_count = base_count or 5
    }
    return instance;
end


----- Multi input action -----

-- `multi_input_action` defines a class to recognize a series of consecutive
-- interactions of the same type, that repeat with roughly the same intervals
-- in between, as being its own type of interaction. E.g. a player may be
-- placing all items of some larger stack in quick succession. Further clicks,
-- e.g. when a stack runs empty, can then be attributed to the former placing
-- action instead of processing it as an independent different kind of
-- interaction, avoiding unintended and unexpected effects or even accidents
-- for the player.
local multi_input_action = {}

-- `multi_input_action:recog(exception)`: To recognize the beginning and
--      progress of a multi input action, call this function whenever a player
--      does the single action that could be a series to be recognized as being
--      a specific multi input action.
-- `exception`: optional; must be a boolean if given; if true, this time no
--              start of a repetitive action will be recognized, but time
--              of last event is updated
function multi_input_action:recog(exception)
    local t = core.get_us_time()
    if t - self.max_dt < (self.last_time or 0) then
        if not exception then
            self.active = true
        -- else  no change
        end
        if self.active and self.adjust_max_dt then
            self:adjust_max_dt(t)
        end
    else  -- delay too long -> reset
        self.active = false
    end
    self.last_time = t
end

-- `multi_input_action:has_ended`: Call this function wherever you want
--      further interaction with circumstances changed (e.g. wielded item is
--      now an empty hand) being recognized as unintended continuation of the
--      initial series that formed a multi input action, rather than being an
--      independent different kind of interaction.
function multi_input_action:has_ended()
    if not self.active then return true end
    -- self.active implies last_time ~= nil

    local t = core.get_us_time()
    -- sill attempting to repeat?
    if t - self.max_dt < self.last_time then
        if self.adjust_max_dt then
            self:adjust_max_dt(t)
        end
        self.last_time = t
    else
        self.active = false  -- not nil, used frequently
        return true
    end
end

-- clamp_fast():
-- Clamps `number` to the range [`min`; `max`] without any safety checks.
-- The caller is responsible for all three parameters being numbers.
local function clamped_fast(number, min, max)
    if number < min then
        number = min
    elseif number > max then
        number = max
    end
    return number
end

-- `multi_input_action:adjust_max_dt(t)`: Adjusts the max interval to recognize
--      an input event as part of a multi input action based on the latest
--      actual interval `t` and up to 4 other, former intervals.
function multi_input_action:adjust_max_dt(t)
    self.running_mean:include(t - self.last_time)
    local mean = self.running_mean:mean()
    self.max_dt = mean + self.offset
    self.max_dt = clamped_fast(self.max_dt, self.min, self.max)
end

-- Constructor to create a new object for multi input action recognition.
-- `max_interval`: Individual action must follow on each other within that
--      interval in order to recognize the beginning or continuation of the
--      a multi input event. Must be a positive number.
-- `auto_adjust`: optional; if true, max_interval is only taken as an initial
--      while auto-adjusted limit within the range [`min`; `max`]
-- `offset`: ignored unless `auto_adjust` is true; the auto adjusted limit will
--      be kept at that `offset` above the average interval between the last 5
--      calls to regoc() (or has_ended()), unless it would exceed `max`.
--      default: 100000us
-- `min`, `max`: absolute limits for auto-adjustment;
--               defaults: max_interval +/- 100000us
function multi_input_action:new(max_interval, auto_adjust,
                                offset, min, max)
    -- no lua-style inheritance -> expecting less runtime overhead
    local instance = {
        recog = self.recog,
        has_ended = self.has_ended,
        max_dt = max_interval,
        adjust_max_dt = auto_adjust and self.adjust_max_dt,
        offset = auto_adjust and (offset or 100000),  -- default: 0.1 sec
        min = auto_adjust and (min or max_interval - 100000),
        max = auto_adjust and (max or max_interval + 100000),
        running_mean = auto_adjust and running_mean:new(4)
        -- `active`: boolean; active or not; default: nil
        -- `last_time`: luanti time of last action in micros secs; default: nil
    }
    return instance
end

 -- per player add a multi_input_action for placing on demand
local multi_placing = {}


-- `minimal.recognize_rapid_placing()`:
-- recognize placing repetitively at high pace to suppress the crafting
-- formspec from opening unintendedly when the stack is emptied.
function minimal.recognize_rapid_placing(itemstack, placer)
    if core.is_player(placer) then
        local player_name = placer:get_player_name()
        local mp = multi_placing[player_name]
        if not mp then
            -- Start with max_interval of 0.5s. If a player clicks slower,
            -- allow up to 0.7s, but not less than 0.5s, see below.
            mp = multi_input_action:new(500000, true, 250000, 500000, 700000)
            multi_placing[player_name] = mp
        end
        -- The trick:
        -- Let mp get the current time. If less than mp's max_interval has
        -- elapsed since last time and stack size is not less than 3, recognize
        -- any further placing and item_place with emptied stack as being part
        -- of the same 'multi-click' action as long a they follow on each other
        -- within mp's adaptive max_interval.
        -- We can assume that it is very likely that the player is not counting
        -- his 'clicks' to 0 to then open crafting intentionally in one go.
        -- With smaller stacks or longer intervals we would risk to prevent a
        -- player from opening crafting intentionally!
        --
        -- However, processing of input events is subject to lag, especially to
        -- lag caused by Luanti blocking the server's main thread when writing
        -- changes of the map every 5 secs, by default. Therefore, recognition
        -- will fail sometimes for fast clickers with slow disks and the max
        -- interval should not go below 0.5s.
        -- (see Luanti issues 15151 and 15125)
        mp:recog(itemstack:get_count() < 3) -- no start if stack was small
        -- NOTE It makes no difference if the player switches among stacks
        --      or not, as long as he keeps placing rapidly in one go.
    end
end


----- overriding minetest.item_place, ... -----

--A new item_place that allows disabling sneak-rightclick behavior for nodes.
--Needed for tech:stick. Also on_place() for empty hand is handled specially
--to open crafting.
--As an additional option it enables to support replacements for on_rightclick()
--whose return value could indicate whether it does also permit item_place_node()
--(unless the wielded item does override on_place() to not call item_place()).
function minetest.item_place(itemstack, placer, pointed_thing, param2)
    --core.log("Exile.item_place")
    -- Call on_rightclick if the pointed node defines it
    local on_click = minimal.pointed_thing_on_rightclick(itemstack, placer,
                                                         pointed_thing)
    if on_click ~= false then
        return on_click or itemstack
    end

    -- item is a type of an empty hand?
    -- -> try to open crafting (default behaviour for external mods, too)
    if itemstack:is_empty() and core.is_player(placer) then
        local mp = multi_placing[placer:get_player_name()]
        if not mp or mp:has_ended() then
            if hand_on_rightclick(placer, pointed_thing) then
                return itemstack, nil
            end
        end
    end

    -- no interaction with pointed thing -> just place a node
    if itemstack:get_definition( ).type == "node" then
        minimal.recognize_rapid_placing(itemstack, placer)
        return minetest.item_place_node( itemstack, placer,
                                         pointed_thing, param2 )
    end
    return itemstack, nil
end


--Basic protection support
local old_is_protected = minetest.is_protected
function minetest.is_protected(pos, name, pos_meta)
    -- custom userdata or tables with get_player_name() permitted
    name = type(name) == "string" and name
        or (type(name) == "userdata"
            or type(name) == "table")
        and name.get_player_name and name:get_player_name()
    if type(name) ~= "string" then
        -- nil things can't touch stuff
        return true
    end
    -- you can specify the meta as third argument
    pos_meta = type(pos_meta) == "userdata" and pos_meta
        or minetest.get_meta(pos)
    local owner = pos_meta:get_string("owner") -- original protector of node
    local bypass = minetest.check_player_privs(name, "protection_bypass")
    -- check if owner is nil, owner is equal to name, or bypass,
    --   otherwise assume no access (false)
    local access = ( owner == ""
                     or owner == name
                     or bypass )
        or false
    -- not the owner, check if there's an access_list
    --   and if they're on the VIP list
    if not access then
        local access_list = pos_meta:get_string("access_list")
        -- if access_list, then parse its json
        access_list = access_list ~= "" and minetest.parse_json(access_list)
            or nil
        if access_list then
            for _,granted in ipairs(access_list) do
                if name == granted then
                    access = true
                    break
                end
            end
        end
    end

    -- no access, is protected
    if not access then
        return true
    end
    -- minetest's old protection always returns false so this is pointless...
    return old_is_protected(pos, name, pos_meta)
end

local old_node_dig = minetest.node_dig
function minetest.node_dig(pos, node, digger)
    -- Return protection nail if node was nailed
    minimal.protection_on_dig(pos,node,digger)
    if minetest.is_player(digger)
        and not minimal.player_in_creative(digger) then

        local witem = digger:get_wielded_item()
        local drops = minetest.get_node_drops(node, witem)
        local inv = digger:get_inventory()
        local full = inv:room_for_item("main", node.name)
        if drops then -- drops something else, maybe multiple items. handle them
            full = false
            inv:set_size("temp", inv:get_size("main"))
            inv:set_list("temp", inv:get_list("main"))
            for k, v in pairs(drops) do
                if not full and inv:room_for_item("temp", drops[k]) then
                    inv:add_item("temp", drops[k])
                else
                    full = true
                end
            end
            inv:set_list("temp", {})
            inv:set_size("temp", 0)
        end
        if full then
            if minimal.stop_on_inv_full(digger) then
                return false
            end
        end
    end
    return old_node_dig(pos, node, digger)
end

-- Transfer metadata from node to item and back.
minetest.register_on_mods_loaded(function()
        -- Add a preserve_metadata callback to all nodes
        for oName, override in pairs( minetest.registered_nodes ) do
            local old_preserve_metadata = override.preserve_metadata
            minetest.override_item(
                oName, {
                    preserve_metadata = function(pos, oldnode, oldmeta, drops)
                        local imeta = drops[1] and drops[1]:get_meta()
                        -- if item meta, provide additional parameter: itemstack meta
                        if imeta then
                            minimal.metadata.preserve_metadata(imeta,oldmeta)
                            if type(old_preserve_metadata) == 'function' then
                                old_preserve_metadata(pos, oldnode,
                                                      oldmeta, drops, imeta)
                            end
                        end

                    end,
            })
            local old_after_place_node = override.after_place_node
            minetest.override_item(
                oName, {
                    after_place_node = function(pos, placer, itemstack,
                                                pointed_thing)
                        local imeta = itemstack:get_meta()
                        local meta = minetest.get_meta(pos)
                        minimal.metadata.after_place_node(imeta,meta)
                        -- provides additional parameters: nodemeta, itemstack meta
                        if type(old_after_place_node) == 'function' then
                            old_after_place_node(pos, placer, itemstack,
                                                 pointed_thing, meta, imeta)
                        end
                    end,
            })
        end

end)

--Increase fall damage
minetest.register_on_player_hpchange(function(player, hp_change, reason)
        if reason.type == "fall" then
            hp_change = hp_change*fall_damage_multiplier
        end
        return hp_change
end, true)

-- Falling

local SCALE = 0.667
local gravity = tonumber(core.settings:get("movement_gravity")) or 9.81

local facedir_to_euler = {
    {y = 0, x = 0, z = 0},
    {y = -math.pi/2, x = 0, z = 0},
    {y = math.pi, x = 0, z = 0},
    {y = math.pi/2, x = 0, z = 0},
    {y = math.pi/2, x = -math.pi/2, z = math.pi/2},
    {y = math.pi/2, x = math.pi, z = math.pi/2},
    {y = math.pi/2, x = math.pi/2, z = math.pi/2},
    {y = math.pi/2, x = 0, z = math.pi/2},
    {y = -math.pi/2, x = math.pi/2, z = math.pi/2},
    {y = -math.pi/2, x = 0, z = math.pi/2},
    {y = -math.pi/2, x = -math.pi/2, z = math.pi/2},
    {y = -math.pi/2, x = math.pi, z = math.pi/2},
    {y = 0, x = 0, z = math.pi/2},
    {y = 0, x = -math.pi/2, z = math.pi/2},
    {y = 0, x = math.pi, z = math.pi/2},
    {y = 0, x = math.pi/2, z = math.pi/2},
    {y = math.pi, x = math.pi, z = math.pi/2},
    {y = math.pi, x = math.pi/2, z = math.pi/2},
    {y = math.pi, x = 0, z = math.pi/2},
    {y = math.pi, x = -math.pi/2, z = math.pi/2},
    {y = math.pi, x = math.pi, z = 0},
    {y = -math.pi/2, x = math.pi, z = 0},
    {y = 0, x = math.pi, z = 0},
    {y = math.pi/2, x = math.pi, z = 0}
}

minetest.register_entity(
    ":__builtin:falling_node", {
        initial_properties = {
            visual = "item",
            visual_size = vector.new(SCALE, SCALE, SCALE),
            textures = {},
            physical = true,
            is_visible = false,
            collide_with_objects = true,
            collisionbox = {-0.5, -0.5, -0.5, 0.5, 0.5, 0.5},
        },

        node = {},
        meta = {},
        floats = false,

        set_node = function(self, node, meta)
            node.param2 = node.param2 or 0
            self.node = node
            meta = meta or {}
            if type(meta.to_table) == "function" then
                meta = meta:to_table()
            end
            for _, list in pairs(meta.inventory or {}) do
                for i, stack in pairs(list) do
                    if type(stack) == "userdata" then
                        list[i] = stack:to_string()
                    end
                end
            end
            local def = minetest.registered_nodes[node.name]
            if not def then
                -- Don't allow unknown nodes to fall
                minetest.log("info",
                             "Unknown falling node removed at "..
                             minetest.pos_to_string(self.object:get_pos()))
                self.object:remove()
                return
            end
            self.meta = meta

            -- Cache whether we're supposed to float on water
            self.floats = minetest.get_item_group(node.name, "float") ~= 0

            -- Save liquidtype for falling water
            self.liquidtype = def.liquidtype

            -- Set entity visuals
            if def.drawtype == "torchlike" or def.drawtype == "signlike" then
                local textures
                if def.tiles and def.tiles[1] then
                    local tile = def.tiles[1]
                    if type(tile) == "table" then
                        tile = tile.name
                    end
                    if def.drawtype == "torchlike" then
                        textures = { "("..tile..")^[transformFX", tile }
                    else
                        textures = { tile, "("..tile..")^[transformFX" }
                    end
                end
                local vsize
                if def.visual_scale then
                    local s = def.visual_scale
                    vsize = vector.new(s, s, s)
                end
                self.object:set_properties({
                        is_visible = true,
                        visual = "upright_sprite",
                        visual_size = vsize,
                        textures = textures,
                        glow = def.light_source,
                })
            elseif def.drawtype ~= "airlike" then
                local itemstring = node.name
                if minetest.is_colored_paramtype(def.paramtype2) then
                    itemstring = minetest.itemstring_with_palette(
                        itemstring, node.param2)
                end
                -- FIXME: solution needed for paramtype2 == "leveled"
                -- Calculate size of falling node
                local s = {}
                s.x = (def.visual_scale or 1) * SCALE
                s.y = s.x
                s.z = s.x
                -- Compensate for wield_scale
                if def.wield_scale then
                    s.x = s.x / def.wield_scale.x
                    s.y = s.y / def.wield_scale.y
                    s.z = s.z / def.wield_scale.z
                end
                self.object:set_properties({
                        is_visible = true,
                        wield_item = itemstring,
                        visual_size = s,
                        glow = def.light_source,
                })
            end

            -- Set collision box (certain nodeboxes only for now)
            local nb_types = {fixed=true, leveled=true, connected=true}
            if def.drawtype == "nodebox" and def.node_box and
                nb_types[def.node_box.type] and def.node_box.fixed then
                local box = table.copy(def.node_box.fixed)
                if type(box[1]) == "table" then
                    box = #box == 1 and box[1]
                        or nil -- We can only use a single box
                end
                if box then
                    if def.paramtype2 == "leveled" and (self.node.level
                                                        or 0) > 0 then
                        box[5] = -0.5 + self.node.level / 64
                    end
                    self.object:set_properties({
                            collisionbox = box
                    })
                end
            end

            -- Rotate entity
            if def.drawtype == "torchlike" then
                self.object:set_yaw(math.pi*0.25)
            elseif ((node.param2 ~= 0 or def.drawtype == "nodebox"
                     or def.drawtype == "mesh")
                and (def.wield_image == "" or def.wield_image == nil))
                or def.drawtype == "signlike"
                or def.drawtype == "mesh"
                or def.drawtype == "normal"
                or def.drawtype == "nodebox" then
                if (def.paramtype2 == "facedir"
                    or def.paramtype2 == "colorfacedir") then

                    local fdir = node.param2 % 32 % 24
                    -- Get rotation from a precalculated lookup table
                    local euler = facedir_to_euler[fdir + 1]
                    if euler then
                        self.object:set_rotation(euler)
                    end
                elseif (def.paramtype2 == "4dir"
                        or def.paramtype2 == "color4dir") then
                    local fdir = node.param2 % 4
                    -- Get rotation from a precalculated lookup table
                    local euler = facedir_to_euler[fdir + 1]
                    if euler then
                        self.object:set_rotation(euler)
                    end
                elseif (def.drawtype ~= "plantlike"
                        and def.drawtype ~= "plantlike_rooted"
                        and (def.paramtype2 == "wallmounted"
                             or def.paramtype2 == "colorwallmounted"
                             or def.drawtype == "signlike")) then
                    local rot = node.param2 % 8
                    if (def.drawtype == "signlike"
                        and def.paramtype2 ~= "wallmounted"
                        and def.paramtype2 ~= "colorwallmounted") then
                        -- Change rotation to "floor" by default
                        --   for non-wallmounted paramtype2
                        rot = 1
                    end
                    local pitch, yaw, roll = 0, 0, 0
                    if def.drawtype == "nodebox"
                        or def.drawtype == "mesh" then

                        if rot == 0 then
                            pitch, yaw = math.pi/2, 0
                        elseif rot == 1 then
                            pitch, yaw = -math.pi/2, math.pi
                        elseif rot == 2 then
                            pitch, yaw = 0, math.pi/2
                        elseif rot == 3 then
                            pitch, yaw = 0, -math.pi/2
                        elseif rot == 4 then
                            pitch, yaw = 0, math.pi
                        end
                    else
                        if rot == 1 then
                            pitch, yaw = math.pi, math.pi
                        elseif rot == 2 then
                            pitch, yaw = math.pi/2, math.pi/2
                        elseif rot == 3 then
                            pitch, yaw = math.pi/2, -math.pi/2
                        elseif rot == 4 then
                            pitch, yaw = math.pi/2, math.pi
                        elseif rot == 5 then
                            pitch, yaw = math.pi/2, 0
                        end
                    end
                    if def.drawtype == "signlike" then
                        pitch = pitch - math.pi/2
                        if rot == 0 then
                            yaw = yaw + math.pi/2
                        elseif rot == 1 then
                            yaw = yaw - math.pi/2
                        end
                    elseif def.drawtype == "mesh"
                        or def.drawtype == "normal"
                        or def.drawtype == "nodebox" then

                        if rot >= 0 and rot <= 1 then
                            roll = roll + math.pi
                        else
                            yaw = yaw + math.pi
                        end
                    end
                    self.object:set_rotation({x=pitch, y=yaw, z=roll})
                elseif (def.drawtype == "mesh"
                        and def.paramtype2 == "degrotate") then
                    local p2 = (node.param2 - (def.place_param2 or 0)) % 240
                    local yaw = (p2 / 240) * (math.pi * 2)
                    self.object:set_yaw(yaw)
                elseif (def.drawtype == "mesh"
                        and def.paramtype2 == "colordegrotate") then
                    local p2 = (node.param2 % 32 - (def.place_param2
                                                    or 0) % 32) % 24
                    local yaw = (p2 / 24) * (math.pi * 2)
                    self.object:set_yaw(yaw)
                end
            end
        end,

        get_staticdata = function(self)
            local ds = {
                node = self.node,
                meta = self.meta,
            }
            return minetest.serialize(ds)
        end,

        on_activate = function(self, staticdata)
            self.object:set_armor_groups({immortal = 1})
            self.object:set_acceleration(vector.new(0, -gravity, 0))

            local ds = minetest.deserialize(staticdata)
            if ds and ds.node then
                self:set_node(ds.node, ds.meta)
            elseif ds then
                self:set_node(ds)
            elseif staticdata ~= "" then
                self:set_node({name = staticdata})
            end
        end,

        try_place = function(self, bcp, bcn)
            local bcd = minetest.registered_nodes[bcn.name]
            -- Add levels if dropped on same leveled node
            if bcd and bcd.paramtype2 == "leveled" and
                bcn.name == self.node.name then
                local addlevel = self.node.level
                if (addlevel or 0) <= 0 then
                    addlevel = bcd.leveled
                end
                if minetest.add_node_level(bcp, addlevel) < addlevel then
                    return true
                elseif bcd.buildable_to then
                    -- Node level has already reached max, don't place anything
                    return true
                end
            end

            -- Decide if we're replacing the node or placing on top
            local np = vector.copy(bcp)
            if bcd and bcd.buildable_to and
                ((not self.floats or bcd.liquidtype == "none") or
                    (self.floats and self.liquidtype ~= "none"
                     and bcd.liquidtype ~= "source")) then
                minetest.remove_node(bcp)
            else
                np.y = np.y + 1
            end

            -- Check what's here
            local n2 = minetest.get_node(np)
            local nd = minetest.registered_nodes[n2.name]
            -- If it's not air or liquid, remove node and replace it with
            -- it's drops
            if n2.name ~= "air" and (not nd or nd.liquidtype ~= "source") then
                if nd and nd.buildable_to == false then
                    nd.on_dig(np, n2, nil)
                    -- If it's still there, it might be protected
                    if minetest.get_node(np).name == n2.name then
                        return false
                    end
                else
                    minetest.remove_node(np)
                end
            end

            -- Create node
            local def = minetest.registered_nodes[self.node.name]
            if def then
                minetest.add_node(np, self.node)
                if self.meta then
                    minetest.get_meta(np):from_table(self.meta)
                end
                if def.sounds and def.sounds.place then
                    minetest.sound_play(def.sounds.place, {pos = np}, true)
                end
            end
            minetest.check_for_falling(np)
            return true
        end,

        on_step = function(self, dtime, moveresult)
            -- Fallback code since collision detection can't tell us
            -- about liquids (which do not collide)
            if self.floats then
                local pos = self.object:get_pos()

                local bcp = pos:offset(0, -0.7, 0):round()
                local bcn = minetest.get_node(bcp)

                local bcd = minetest.registered_nodes[bcn.name]
                if bcd and bcd.liquidtype ~= "none" then
                    if self:try_place(bcp, bcn) then
                        self.object:remove()
                        return
                    end
                end
            end

            assert(moveresult)
            if not moveresult.collides then
                return -- Nothing to do :)
            end

            local bcp, bcn
            local player_collision
            if moveresult.touching_ground then
                for _, info in ipairs(moveresult.collisions) do
                    if info.type == "object" then
                        if info.axis == "y" and info.object:is_player() then
                            player_collision = info
                        end
                    elseif info.axis == "y" then
                        bcp = info.node_pos
                        bcn = minetest.get_node(bcp)
                        break
                    end
                end
            end

            if not bcp then
                -- We're colliding with something, but not the ground.
                -- Irrelevant to us.
                if player_collision then
                    -- Continue falling through players by moving a little into
                    -- their collision box
                    -- TODO: this hack could be avoided in the future if objects
                    --       could choose who to collide with
                    local vel = self.object:get_velocity()
                    self.object:set_velocity(vector.new(
                                                 vel.x,
                                                 player_collision.old_velocity.y,
                                                 vel.z
                    ))
                    self.object:set_pos(self.object:get_pos():offset(0, -0.5, 0))
                end
                return
            elseif bcn.name == "ignore" then
                -- Delete on contact with ignore at world edges
                self.object:remove()
                return
            end

            local failure = false

            local pos = self.object:get_pos()
            local distance = vector.apply(vector.subtract(pos, bcp), math.abs)
            if distance.x >= 1 or distance.z >= 1 then
                -- We're colliding with some part of a node that's sticking out
                -- Since we don't want to visually teleport, drop as item
                failure = true
            elseif distance.y >= 2 then
                -- Doors consist of a hidden top node and a bottom node that is
                -- the actual door. Despite the top node being solid, the moveresult
                -- almost always indicates collision with the bottom node.
                -- Compensate for this by checking the top node
                bcp.y = bcp.y + 1
                bcn = minetest.get_node(bcp)
                local def = minetest.registered_nodes[bcn.name]
                if not (def and def.walkable) then
                    failure = true -- This is unexpected, fail
                end
            end

            -- Try to actually place ourselves
            if not failure then
                failure = not self:try_place(bcp, bcn)
            end

            if failure then
                local drops = minetest.get_node_drops(self.node, "")
                for _, item in pairs(drops) do
                    minetest.add_item(pos, item)
                end
            end
            self.object:remove()
        end
})

local function convert_to_falling_node(pos, node)
    local obj = core.add_entity(pos, "__builtin:falling_node")
    if not obj then
        return false
    end
    -- remember node level, the entities' set_node() uses this
    node.level = core.get_node_level(pos)
    local meta = core.get_meta(pos)
    local metatable = meta and meta:to_table() or {}

    local def = core.registered_nodes[node.name]
    if def and def.sounds and def.sounds.fall then
        core.sound_play(def.sounds.fall, {pos = pos}, true)
    end

    obj:get_luaentity():set_node(node, metatable)
    core.remove_node(pos)
    return true, obj
end

local builtin_shared = {}

builtin_shared.check_attached_node = function(p, n, group_rating)
    local def = core.registered_nodes[n.name]
    local d = vector.zero()
    if group_rating == 3 then
        -- always attach to floor
        d.y = -1
    elseif group_rating == 4 then
        -- always attach to ceiling
        d.y = 1
    elseif group_rating == 2 then
        -- attach to facedir or 4dir direction
        if (def.paramtype2 == "facedir" or
            def.paramtype2 == "colorfacedir") then
            -- Attach to whatever facedir is "mounted to".
            -- For facedir, this is where tile no. 5 point at.

            -- The fallback vector here is in case 'facedir to dir' is nil due
            -- to voxelmanip placing a wallmounted node without resetting a
            -- pre-existing param2 value that is out-of-range for facedir.
            -- The fallback vector corresponds to param2 = 0.
            d = core.facedir_to_dir(n.param2) or vector.new(0, 0, 1)
        elseif (def.paramtype2 == "4dir" or
                def.paramtype2 == "color4dir") then
            -- Similar to facedir handling
            d = core.fourdir_to_dir(n.param2) or vector.new(0, 0, 1)
        end
    elseif def.paramtype2 == "wallmounted" or
        def.paramtype2 == "colorwallmounted" then
        -- Attach to whatever this node is "mounted to".
        -- This where tile no. 2 points at.

        -- The fallback vector here is used for the same reason as
        -- for facedir nodes.
        d = core.wallmounted_to_dir(n.param2) or vector.new(0, 1, 0)
    else
        d.y = -1
    end
    local p2 = vector.add(p, d)
    local nn = core.get_node(p2).name
    local def2 = core.registered_nodes[nn]
    if def2 and not def2.walkable then
        return false
    end
    return true
end

local function drop_attached_node(p)
    local n = core.get_node(p)
    local drops = core.get_node_drops(n, "")
    local def = core.registered_items[n.name]
    if def and def.preserve_metadata then
        local oldmeta = core.get_meta(p):to_table().fields
        -- Copy pos and node because the callback can modify them.
        local pos_copy = vector.copy(p)
        local node_copy = {name=n.name, param1=n.param1, param2=n.param2}
        local drop_stacks = {}
        for k, v in pairs(drops) do
            drop_stacks[k] = ItemStack(v)
        end
        drops = drop_stacks
        def.preserve_metadata(pos_copy, node_copy, oldmeta, drops)
    end
    if def and def.sounds and def.sounds.fall then
        core.sound_play(def.sounds.fall, {pos = p}, true)
    end
    core.remove_node(p)
    for _, item in pairs(drops) do
        local pos = {
            x = p.x + math.random()/2 - 0.25,
            y = p.y + math.random()/2 - 0.25,
            z = p.z + math.random()/2 - 0.25,
        }
        core.add_item(pos, item)
    end
end

function minetest.check_single_for_falling(p)
    local n = minetest.get_node(p)
    if minetest.get_item_group(n.name, "falling_node") ~= 0 then
        local p_bottom = vector.offset(p, 0, -1, 0)
        -- Only spawn falling node if node below is loaded
        local n_bottom = minetest.get_node_or_nil(p_bottom)
        local d_bottom = n_bottom and minetest.registered_nodes[n_bottom.name]
        if d_bottom then
            local same = n.name == n_bottom.name
            -- Let leveled nodes fall if it can merge with the bottom node
            if same and d_bottom.paramtype2 == "leveled" and
                minetest.get_node_level(p_bottom) <
                minetest.get_node_max_level(p_bottom) then
                local success, _ = convert_to_falling_node(p, n)
                return success
            end
            local d_falling = minetest.registered_nodes[n.name]
            -- Otherwise only if the bottom node is considered "fall through"
            if not same and
                (not d_bottom.walkable or d_bottom.buildable_to) and
                ((minetest.get_item_group(n.name, "float") == 0 or
                  d_bottom.liquidtype == "none") or
                    (minetest.get_item_group(n.name, "float") > 0 and
                     d_falling.liquidtype == "source" and
                     d_bottom.liquidtype ~= "source")) then
                local success, _ = convert_to_falling_node(p, n)
                return success
            end
        end
    end

    local an = minetest.get_item_group(n.name, "attached_node")
    if an ~= 0 then
        if not builtin_shared.check_attached_node(p, n, an) then
            drop_attached_node(p)
            return true
        end
    end

    return false
end
