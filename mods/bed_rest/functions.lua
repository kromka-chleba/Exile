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
clothing = clothing
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


-- if donning == false, remove blanket from bed, else put blanket on bed
--#TODO works but display in clothing tab doesn't update well, until I also change cloths
local function wear_blanket(player, bed_pos, donning)
    local bed_meta = minetest.get_meta(bed_pos)
    local bedInv = bed_meta:get_inventory()
    bedInv:set_size('main',1)

    
    local name = player:get_player_name()
    local p_inv = player:get_inventory()
    
    local newstack

    local to_remove
    
    --if I want to remove the blanket
    if donning==false then
        -- checking bed inventory
        newstack = bedInv:get_stack('main',1)
        --if we had a blanket in bed
        if newstack and not newstack:is_empty() then
            -- put it in player's inventory or back to bed
            -- if we can, take it in inventory
            if p_inv:room_for_item('main',newstack) then
                p_inv:add_item('main',newstack)
                -- empty bed inventory
                bedInv:set_stack('main',1,ItemStack(''))
                -- update bed's infotext
                bed_meta:set_string("blanket","")
                minimal.infotext_set_new(bed_pos, bed_meta)
                -- else leave it on the bed
            else
                minetest.chat_send_player(
                player:get_player_name(), S("You have no room to take the blanket with you, so you left it on the bed."))
                -- #TODO weirdly if not updatinf infostext here I got no infotext anymore ?
                bed_meta:set_string("blanket",S("Bed: Contains Blanket"))
                minimal.infotext_set_new(bed_pos, bed_meta)
                
            end
            -- empty clothing slot
            p_inv:set_stack('blanket',1,ItemStack(''))
            --if bed has no blanket to remove  
        else
            minetest.log("There is no blanket to remove from the bed")
            return
        end    
        
    --if I want to put a blanket
    else
        -- do I have a blanket to put in from inventory ?
        newstack = blanket_find(p_inv, "main")
        -- I have a blanket to place
        if newstack and not newstack:is_empty() then
            -- in case bed is not empty, take what is in it
            to_remove = bedInv:get_stack('main',1)            
            -- put new blanket in bed inventory
            bedInv:set_stack('main',1,newstack)
            -- put it in clothing slot too
            p_inv:set_stack('blanket',1,newstack)
            -- update info
            bed_meta:set_string("blanket",S("Bed: Contains Blanket"))
            minimal.infotext_set_new(bed_pos, bed_meta)
            
            -- if the bed was not empty, I have an old blanket to deal with
            if not to_remove:is_empty() then
                -- if we can, take it in inventory
                if p_inv:room_for_item('main',to_remove) then
                    p_inv:add_item('main',to_remove)
                -- else put it on the ground
                else
                    local p_pos = player:get_pos()
                    minetest.item_drop(to_remove, player, p_pos)
                    minetest.chat_send_player(
                    player:get_player_name(), S("You have no room to hold your blanket, so you drop it."))
                    minetest.sound_play("nodes_nature_dig_snappy",
                    {pos = p_pos, gain = .8, max_hear_distance = 2}) 
                end
            end        
            -- I have no blanket to place
        else
            minetest.log("There is no blanket to add to the bed")
            return -- not sure if I should return flase to indicate the fail
        end
    end   
    -- update player settings 
    -- #TODO update of model is broken
    player_api.update_temp(player)
    player_api.set_texture(player)
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

local function stopmove(player, pos, lives, meta)
    if (not player) or (not player:is_player()) then return end
    if not meta then meta = player:get_meta() end
    if lives then
        local newlives = meta:get_string("lives")
        if lives < tonumber(newlives) then
            return -- Player has died before this fired
        end
    end
    local dropspot = vector.new(pos.x, pos.y + 0.6, pos.z)
    player:set_attach(minetest.add_entity(dropspot, "bed_rest:bedspot"), "")
end

-----------------------------------------------------------------
local function lay_down(player, level, pos, bed_pos, state, skip)
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

        --remove blanket
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
        local pmeta = player:get_meta()
        local velo = player:get_velocity() or player:get_player_velocity()
        if velo.x ~= 0 then return end
        if velo.y ~= 0 then return end
        if velo.z ~= 0 then return end
        -- Check if bed is occupied
        for nm, other_pos in pairs(bed_rest.bed_position) do
            if vector.distance(bed_pos, other_pos) < 0.1
                and nm ~= name then
                minetest.chat_send_player(name, S("This bed is already occupied!"))
                local meta = minetest.get_meta(bed_pos)
                minimal.infotext_set_new(bed_pos, meta,
                                         {status=S('Status: Occupied by @1',nm)})
                return false
            end
        end
        bed_rest.pos[name] = pos
        bed_rest.bed_position[name] = bed_pos
        bed_rest.player[name] = 1
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

        --wear a blanket from inventory
        wear_blanket(player, bed_pos, true)

        -- physics, eye_offset, etc
        player:set_eye_offset({x = 0, y = -12, z = 0}, {x = 0, y = -4.5, z = 0})
        local yaw, param2 = get_look_yaw(bed_pos)
        player:set_look_horizontal(yaw)
        local dir = minetest.facedir_to_dir(param2)
        local p = {x = bed_pos.x + dir.x / 2, y = bed_pos.y,
                   z = bed_pos.z + dir.z / 2}
        --clear physics
        player_monoids.speed:del_change(player, "health:physics")
        player_monoids.jump:del_change(player, "health:physics")
        player_monoids.speed:del_change(player, "health:physics_HE")
        player_monoids.jump:del_change(player, "health:physics_HE")
        player_monoids.speed:add_change(player, 0, "bed_rest:resting")
        player_monoids.jump:add_change(player, 0, "bed_rest:resting")
        player_monoids.gravity:add_change(player, 0, "bed_rest:resting")
        local lives = tonumber(pmeta:get_string("lives"))
        stopmove(player,p, lives, pmeta)
        player_api.player_attached[name] = true
        hud_flags.wielditem = false
        player_api.set_animation(player, "lay")
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
function bed_rest.on_rightclick(pos, player, level)
    local name = player:get_player_name()
    local ppos = player:get_pos()

    if bed_rest.player[name] then
        lay_down(player, nil, nil, nil, false)
    else
        -- move to bed
        lay_down(player, level, ppos, pos)
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
            lay_down(player, bed_rest.level[name], bed_rest.pos[name],
                     bed_rest.bed_position[name], true)
        end
end
)
