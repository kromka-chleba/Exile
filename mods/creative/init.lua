-- creative/init.lua

-- Load support for MT game translation.
local S = minetest.get_translator("creative")

creative = {}
creative.get_translator = S
sfinv = sfinv

local creative_mode_cache = minetest.settings:get_bool("creative_mode")

-- the strong hands you get from being in creative
do
    -- Dig time is modified according to difference (leveldiff) between tool
    -- 'maxlevel' and node 'level'. Digtime is divided by the larger of
    -- leveldiff and 1.
    -- To speed up digging in creative, hand 'maxlevel'/'digtime' have been
    -- increased such that nodes of differing levels have an insignificant
    -- effect on digtime.
    local digtime = 42
    local caps = {times = {digtime, digtime, digtime},
      uses = 0, maxlevel = 256}
    -- use register node to have a proper not ugly texture, does not affect hand functionality at all
    core.register_node("creative:hand",{
        --type = "none",
        range = 10,
        tool_capabilities = {
            full_punch_interval = 0.5,
            max_drop_level = 3,
            groupcaps = {
                crumbly = caps,
                cracky  = caps,
                snappy  = caps,
                choppy  = caps,
                oddly_breakable_by_hand = caps,
                -- dig_immediate group doesn't use value 1.
                --  Value 3 is instant dig
                dig_immediate =
                    {times = {[2] = digtime, [3] = 0}, uses = 0,
                     maxlevel = 256},
            },
            damage_groups = {fleshy = 10},
        },
        tiles = {"creative_hand.png"},
        wield_scale = {x=0.5,y=0.9,z=0.5},
        liquids_pointable = true
    })
end

-- prevent one change from overriding te other
-- e.g. when clothing temp is changed, it changes the max and min simultaneously and both will override eachother
local creative_updating_for = {}
-- check creative updating for - quickie function for handling the above check
-- value is what value it should be changed to on success
local function ccuf(name, value)
    local checked = creative_updating_for[name]
    if checked == value then return true end -- if value equal to checked, return true
    creative_updating_for[name] = value -- update
end
-- give players the creative menu and funky strong hands
-- onnew is if this is called when player is joining or respawning
-- nonotif prevents message production
local function update_creative_attributes(plr, granter_name, onnew, nonotif)
    -- permit player or player name argument for plr, save name if string
    local name = type(plr) == "string" and plr
    plr = name and core.get_player_by_name(name) or core.is_player(plr) and plr
    if not plr then return end -- whaddya you mean we can't play with ghosts?
    name = name or plr:get_player_name() -- ensure we get a proper name
    -----------------------------------------
    -- check if we're already doing this
    if ccuf(name, true) then return end -- already doing this, return!
    -----------------------------------------
    local in_creative = minimal.player_in_creative(name)
    -- if onnew and not in creative, don't run this
    if onnew and not in_creative then
        return ccuf(name, nil)
    end
    -- do on a delay to prevent conflict with other mods like player_api
    core.after(0, function()
        -- get current hand to check whether or not we were in creative prior
        if not core.is_player(plr) then return end
        local pinv = plr:get_inventory()
        local chand = pinv:get_stack("hand", 1)
        local cdef = chand:get_definition() or {} -- current hand definition
        if cdef.name ~= "creative:hand" and in_creative or -- going into creative
          -- going out of creative
          cdef.name == "creative:hand" and not in_creative then
            if not nonotif then
                core.chat_send_player(name, "* * * * * *")
                -- granted
                if in_creative then
                    core.chat_send_player(name, "You have entered creative mode!")
                    core.sound_play({
                        name = "creative_jingle_grant", to_player = name, pitch = math.random(90,110)/100, gain = 0.1
                    })
                -- revoked
                else
                    core.chat_send_player(name, "You have had creative mode revoked!")
                    core.sound_play({
                        name = "creative_jingle_revoke", to_player = name, pitch = math.random(90,110)/100, gain = 0.1
                    })
                end
                core.chat_send_player(name, "* * * * * *")
            end
        -- oops, got (or lost!) the creative privilege again, don't update!
        else
            return ccuf(name, nil) -- remove from updating for list
        end
        -- creative menu, or regular!!!
        if in_creative then
            sfinv.set_page(plr, sfinv.get_homepage_name(plr))
        else
            sfinv.set_player_inventory_formspec(plr)
        end
        -- powerful hands handling
        -- let us get what we most desire
        if in_creative then
            -- save prior non-creative hand into the inventory
            pinv:set_stack("hand", 2, chand)
            -- powerful hands!
            pinv:set_stack("hand", 1, "creative:hand")
        -- no more powerful hands!
        else
            local replace = pinv:get_stack("hand", 2)
            pinv:set_stack("hand", 1, replace)
        end
        -- our job here is done
        ccuf(name, nil)
    end)
end

-- check if we're in creative, add creative-ness if so
core.register_on_joinplayer(function(plr)
    update_creative_attributes(plr, nil, true)
end)
-- anything relating to player api such as equiping clothing or going into beds changes the hand back
-- run on a delay so that the changes that change comfort temp on start don't cause this to run
-- this changes whenever the player respawns, so serves as an alternative to register_on_respawnplayer lol
core.after(1, function()
    HEALTH = HEALTH
    HEALTH.register_on_stat_change(function(player, name, value, meta)
        if name == "clothing_temp_max" or name == "clothing_temp_min" then
            update_creative_attributes(player, nil, nil, true)
        end
    end)
end)

minetest.register_privilege(
    "creative", {
        description = S("Allow player to use creative inventory"),
        give_to_singleplayer = false,
        give_to_admin = false,
        on_grant = update_creative_attributes,
        on_revoke = update_creative_attributes,
})

dofile(minetest.get_modpath("creative") .. "/inventory.lua")

-- Unlimited node placement
minetest.register_on_placenode(function(pos, newnode, placer,
                                        oldnode, itemstack)
    if not core.is_player(placer) then return end
    return minimal.player_in_creative(placer)
end)

-- Don't pick up if the item is already in the inventory
local old_handle_node_drops = minetest.handle_node_drops
function minetest.handle_node_drops(pos, drops, digger)
    -- not a player or not in creative
    if not core.is_player(digger) or not minimal.player_in_creative(digger) then
        return old_handle_node_drops(pos, drops, digger)
    end
    -- we're in CREATIVE BABYYYYYY
    local inv = digger:get_inventory()
    if inv then
        for _, item in ipairs(drops) do
            if not inv:contains_item("main", item, true) then
                inv:add_item("main", item)
            end
        end
    end
end
