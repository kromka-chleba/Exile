-----------------------------------------------------------------
--BED REST FUNCTIONS
--
-----------------------------------------------------------------
local S = minetest.get_translator("bed_rest")
local NS = function(s) return s end

local pi = math.pi
--silence luacheck warnings about accessing globals:
bed_rest = bed_rest
local store = bed_rest.store

player_api = player_api
player_monoids = player_monoids
minimal = minimal

-- after this many IRL days, beds in multiplayer will no longer be protected
local days_until_timeout = 7

-- find if there is a blanket in the inventory list
local function blanket_find(inv,listName)
    local cinv = inv:get_list(listName)
    for stkidx,itemstk in pairs(cinv) do
        if not (itemstk:is_empty()) then
            if minetest.get_item_group(itemstk:get_name(),"blanket") > 0 then
                if itemstk:get_count() > 1 then
                    -- prevent the allowance of 2 blankets being transferred at once
                    local old_itemstk = itemstk
                    itemstk = itemstk:take_item(1)
                    inv:set_stack(listName,stkidx,old_itemstk)
                else
                    -- using "remove_item" causes colour domination due to itemstring issues I imagine
                    inv:set_stack(listName,stkidx,ItemStack(''))
                end

                return itemstk
            end
        end
    end
    return nil
end

--[[ Dealing with my blanket when standing up from a bed
    * if `leave_on_bed` is true, I leave leave it on the bed
    * else, I wil take it back
    Also updates infotext.
]]
local function leave_blanket(player, bed_pos, leave_on_bed)
    -- get player's inv
    local p_inv = player:get_inventory()
    -- gets bed's meta and inv
    local bed_meta = minetest.get_meta(bed_pos)
    local bedInv = bed_meta:get_inventory()
    -- to fill meta.blanket for infotext
    local meta_blanket = ""
    -- if I had a blanket on me
    if not p_inv:is_empty('blanket') then
        local blanket = p_inv:get_stack('blanket',1)
        -- If we have to leave the blanket on the bed
        if leave_on_bed then
            -- Creates a dedicated inventory
            bedInv:set_size('main',1)
            -- adds blanket to bed's inventory'
            bedInv:set_stack('main',1,blanket)
            -- updates infotext
            meta_blanket = S("Contains Blanket")
        -- else give it back to the player
        else
            if p_inv:room_for_item("main",blanket) then
                p_inv:add_item("main",blanket)
            else
                core.item_drop(blanket, player, player:get_pos())
                --minimal.send_message(player, nil, ("Inventory is full : the clothing you wore was thrown on the floor."),2)
                minimal.warn_inv_full(player)
            end
        end
        -- in any case empty clothing slot
        p_inv:set_stack('blanket',1,ItemStack(''))

    -- else bed remain empty
    end
    bed_meta:set_string("blanket", meta_blanket)
    minimal.infotext_set_new(bed_pos, bed_meta)
end

--[[ Dealing with my blanket when going into bed
    * If a blanket is already on the bed, I will equip that one
    * Else, I will look in my main inventory to see if I have one to equip, and if yes, equip it
    Also updates infotext
]]
local function equip_blanket(player, bed_pos, bed_meta)
    -- get player's inv
    local p_inv = player:get_inventory()
    -- gets bed's meta and inv
    local bmeta = bed_meta or minetest.get_meta(bed_pos)
    local bedInv = bmeta:get_inventory()

    local blanket
    if not bedInv:is_empty("main") then
        blanket = bedInv:get_stack('main',1)
    end
    -- if a blanket is already on the bed, equip that one
    if blanket and not blanket:is_empty() then
        p_inv:set_stack('blanket',1,blanket)
        bedInv:set_stack('main',1,ItemStack(''))
        -- blanket is on me (or no blanket) and not in the bed's inv anymore
        bed_meta:set_string("blanket","")
        minimal.infotext_set_new(bed_pos, bed_meta)

    -- else, try to take one from inventory
    else
        -- try to remove one from inventory
        blanket = blanket_find(p_inv, "main")
        -- if succeed
        if blanket and not blanket:is_empty() then
            -- equip this blanket
            p_inv:set_stack('blanket',1,blanket)

        -- else, I have no blanket, do nothing
        else
            return
        end
    end
end


--[[ This function deals with blankets when I go in or out of a bed:
    * `donning` = `true` if I go IN the bed (tries to equip a blanket)
    * `donning` = `false` if I go OUT of the bed (leaves it or take it back)
    ]]

local function wear_blanket(player, bed_pos, donning)
    if not bed_pos then return end

    --if stand up and leave a blanket in the bed from my cloth inventory
    if donning==false then
        -- checking if this is a sleeping spot for divergent behavior
        -- #TODO adjust code so that setting "leave_on_bed" is in node's def
        local node = minetest.get_node(bed_pos)
        local is_sleeping_spot = string.find(node.name, "sleeping_spot")
        if is_sleeping_spot then
            leave_blanket(player, bed_pos, false)
        else
            leave_blanket(player, bed_pos, true)
        end

    --if I want to put a blanket on me when going in bed
    else
        equip_blanket(player, bed_pos)
    end
    -- update player look and cloth effects
    player_api.update_player(player)
end

-----------------------------------------------------------------
local function get_look_yaw(pos)
    local rotation = minetest.get_node(pos).param2
    if rotation > 3 then
        rotation = rotation % 4 -- Mask colorfacedir values
    end
    if rotation == 1 then
        return pi / 2, rotation
    elseif rotation == 3 then
        return -pi / 2, rotation
    elseif rotation == 0 then
        return pi, rotation
    else
        return 0, rotation
    end
end

local bedspot = {
    initial_properties = {collisionbox = {0, -0.025, 0, 0.01, 0.01, 0.01},
                          visual="upright_sprite",
                          textures = { "empty.png" },
                          physical = true
                         },
    on_activate = function(self) -- fall down until we hit the bed, aka pomf
        self.object:set_velocity(vector.new(0,-2,0))
    end,
    on_step = function(self, dtime, moveresult)
        if not self.timer then self.timer = 0.1 return end
        self.timer = self.timer - dtime
        if self.timer > 0 then return end
        self.timer = nil
        self.count = ( self.count or 0 ) + 1
        local chrilden = self.object:get_children()
        if self.count > 9 and #chrilden > 0 then
            chrilden[1]:set_detach()
            table.remove(chrilden, 1) -- to new york, too lady to rest
        end
        if #chrilden < 1 then -- cannot frigth back?!
            self.object:remove()
            return
        end
        local player = chrilden[1]
        self.object:set_yaw(player:get_look_horizontal())
    end,
    on_attach_child = function(self, child)
        self.object:set_yaw(child:get_look_horizontal())
    end,
    on_detach_child = function(self, child)
        self.object:remove()
    end
}
minetest.register_entity("bed_rest:bedspot", bedspot)

local function stopmove(player, pos)
    if (not player) or (not player:is_player()) then return end
    local dropspot = vector.new(pos.x, pos.y + 0.6, pos.z)
    player:set_attach(minetest.add_entity(dropspot, "bed_rest:bedspot"), "")
end

-----------------------------------------------------------------
local function lay_down(player, level, pos, bed_pos, state, skip, seating)
    local name = player:get_player_name()
    local hud_flags = player:hud_get_flags()

    if not player or not name then
        return
    end

    local st = player_api.get_state_by_name(name)

    -- stand up
    if state ~= nil and not state then
        local p = bed_rest.pos[name] or nil
        local bedp = bed_rest.bed_position[name] or nil
        if bedp ~= nil then
            local bed_meta = minetest.get_meta(bedp)
            bed_meta:set_string('status','') -- remove status
            minimal.infotext_clear(bedp, bed_meta)
        end
        bed_rest.player[name] = nil
        bed_rest.level[name] = nil
        st:clear("resting")

        -- skip here to prevent sending player specific changes
        -- (used for players who may have left, and have no player object)
        if skip then
            bed_rest.bed_position[name] = nil
            return
        end

        if p and minimal.safe_landing_spot(p) then
            player:set_pos(p)
        elseif bed_rest.bed_position[name] then
            player:set_pos(bed_rest.bed_position[name])
        end
        bed_rest.bed_position[name] = nil

        --remove blanket from the player cloths
        if bedp then
            wear_blanket(player, bedp, false)
        elseif bed_pos then
            wear_blanket(player, bed_pos, false)
        end

        -- physics, eye_offset, etc
        player:set_eye_offset({x = 0, y = 0, z = 0}, {x = 0, y = 0, z = 0})
        player_api.player_attached[name] = false
        player:set_detach()
        player_monoids.speed:del_change(player, "bed_rest:resting")
        player_monoids.jump:del_change(player, "bed_rest:resting")
        player_monoids.gravity:del_change(player, "bed_rest:resting")
        hud_flags.wielditem = true
        player_api.set_animation(player, "stand")

        -- lay down, provided we have a valid bed position
    elseif bed_pos then
        -- Check if bed is occupied
        for nm, other_pos in pairs(bed_rest.bed_position) do
            if vector.distance(bed_pos, other_pos) < 0.1
                and nm ~= name then
                if not seating then
                    minetest.chat_send_player(name, S("This bed is already occupied!"))
                else
                    minetest.chat_send_player(name, S("This seat is already occupied!"))
                end
                local meta = minetest.get_meta(bed_pos)
                minimal.infotext_set_new(bed_pos, meta,
                                         {status=S('Status: Occupied by @1',nm)})
                return false
            end
        end
        -- if bed/seat is free, lay down/sit
        bed_rest.pos[name] = pos
        bed_rest.bed_position[name] = bed_pos
        if seating then
            bed_rest.player[name] = 2
        else
            bed_rest.player[name] = 1
        end
        bed_rest.level[name] = level

        st:add("resting")
        if not minetest.is_singleplayer() then
            minimal.infotext_set_new(bed_pos, nil,
                                     {status=S('Status: Occupied by @1', name)})
            minetest.get_node_timer(bed_pos):start(60 * 60 * 24 *
                                                   days_until_timeout)
        end

        --check with break taker
        bed_rest.break_taker(name,player:get_meta():get_string("breaktaker"))

        if not seating then -- if I am on a bed
            --wear a blanket from inventory or use one in the bed if any
            wear_blanket(player, bed_pos, true)
            -- physics, eye_offset, etc
            player:set_eye_offset(
                {x = 0, y = -12, z = 0},
                {x = 0, y = -4.5, z = 0})
        else -- if I am sitting
            player:set_eye_offset(
                {x = 0, y = -4, z = 0},
                {x = 0, y = -2, z = 0})
        end

        local yaw, param2 = get_look_yaw(bed_pos)
        player:set_look_horizontal(yaw)
        local dir = minetest.facedir_to_dir(param2)

        local p = bed_pos
        if not seating then -- if I am on a bed
            p= {x = bed_pos.x + dir.x / 2, y = bed_pos.y,
                z = bed_pos.z + dir.z / 2}
        end
        --clear physics
        player_monoids.speed:del_change(player, "health:physics")
        player_monoids.jump:del_change(player, "health:physics")
        player_monoids.speed:del_change(player, "health:physics_HE")
        player_monoids.jump:del_change(player, "health:physics_HE")
        player_monoids.speed:add_change(player, 0, "bed_rest:resting")
        player_monoids.jump:add_change(player, 0, "bed_rest:resting")
        player_monoids.gravity:add_change(player, 0, "bed_rest:resting")
        stopmove(player,p)

        player_api.player_attached[name] = true
        hud_flags.wielditem = false

        if not seating then
            player_api.set_animation(player, "lay")
        else
            player_api.set_animation(player, "sit")
        end
    else -- no valid bed pos? put them back. Cut down version of "stand up"
        local p = bed_rest.pos[name] or nil
        if p then -- better hope it's safe, we don't know where your bed is
            player:set_pos(p)
        end
        bed_rest.player[name] = nil
        bed_rest.level[name] = nil
    end

    local brtemp = {}
    brtemp.level = bed_rest.level
    brtemp.player = bed_rest.player
    brtemp.pos = bed_rest.pos
    brtemp.bed_position = bed_rest.bed_position

    store:set_string("bedrest", minetest.serialize(brtemp))
    player:hud_set_flags(hud_flags)
end

--------------------------------------------
function bed_rest.on_rightclick(pos, player, level, seating)
    local name = player:get_player_name()
    local ppos = player:get_pos()

    if bed_rest.player[name] then
        lay_down(player, nil, nil, nil, false, nil, seating)
    else
        -- move to bed
        lay_down(player, level, ppos, pos, nil, nil, seating)
    end
end

--------------------------------------------
function bed_rest.can_dig(bed_pos, player)
    -- Check all players in bed which one is at the expected position
    for nm, player_bed_pos in pairs(bed_rest.bed_position) do
        if vector.equals(bed_pos, player_bed_pos) then
            if minetest.check_player_privs(player, "protection_bypass") then
                --admins can remove old beds
                bed_rest.bed_position[nm] = nil
                return true
            end
            return false
        end
    end
    return true
end

function bed_rest.on_timer(pos, elapsed)
    -- Called after configured timeout to clear bed ownership
    local meta = minetest.get_meta(pos)
    for nm, other_pos in pairs(bed_rest.bed_position) do
        if vector.distance(pos, other_pos) < 0.1 then
            bed_rest.bed_position[nm] = nil
            if not minetest.is_singleplayer() then
                minimal.infotext_set_new(pos, meta,
                                         {status=S('Status: Occupied by @1 (old)',
                                                   nm)})
            end
            return false
        end
    end
end

--------------------------------------------
--Jump out of bed
local jtimer = 0
minetest.register_globalstep(function(dtime)
        jtimer = jtimer + dtime
        if jtimer > 0.2 then
            for _, player in ipairs(minetest.get_connected_players()) do
                local name = player:get_player_name()
                if bed_rest.player[name] then
                    if math.floor(player:get_player_control_bits() / 16) % 2 == 1 then
                        lay_down(player, nil, nil, nil, false) -- jump out of bed
                    end
                end
            end
            jtimer = 0
        end
end)

minetest.register_on_dieplayer(function(player)
        local name = player:get_player_name()
        local hud_flags = player:hud_get_flags()

        if bed_rest.bed_position[name] then
            wear_blanket(player, bed_rest.bed_position[name], false)
        end

        bed_rest.player[name] = nil
        bed_rest.bed_position[name] = nil
        bed_rest.level[name] = nil

        -- physics, eye_offset, etc
        player:set_eye_offset({x = 0, y = 0, z = 0}, {x = 0, y = 0, z = 0})
        player:set_look_horizontal(math.random(1, 180) / 100)
        player_api.player_attached[name] = false
        player_monoids.speed:del_change(player, "bed_rest:resting")
        player_monoids.jump:del_change(player, "bed_rest:resting")
        player_monoids.gravity:del_change(player, "bed_rest:resting")
        hud_flags.wielditem = true
        player_api.set_animation(player, "stand")

end)

--get start time of session
minetest.register_on_joinplayer(function(player)
        local name = player:get_player_name()
        bed_rest.session_start[name] = os.time()
        -- 30 minutes is 1800 ticks, so multiply by 60
        bed_rest.session_limit[name] =
            minetest.settings:get('exile_breaktime') * 60
        if bed_rest.player[name] then
            -- compatibility for new world using new table system
            if type(bed_rest.player[name]) == "table" then
                bed_rest.player[name] = bed_rest.player[name].sit and 2
                                        or 1
            end
            lay_down(player, bed_rest.level[name], bed_rest.pos[name],
                     bed_rest.bed_position[name], true, nil,
                     (bed_rest.player[name]==2))
        end
end
)
