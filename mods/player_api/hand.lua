
-- we have to do this because damage groups does not properly transfer for held items
-- with a custom hand, because yay! Engine!!!
core.override_item("", {
                       tool_capabilities =
                           {damage_groups = {fleshy=minimal.hand_dmg}},
                       liquids_pointable = true
                       }
)
-- The hand
-- does not override core.registered_items[""]
-- use core.registered_items["player_api:hand"] instead
minetest.register_item(
    "player_api:hand", {
        type = "none",
        wield_image = "player_hand.png",
        wield_scale = {x=1,y=1,z=2.5},
        tool_capabilities = {
            full_punch_interval = minimal.hand_punch_int,
            max_drop_level = minimal.hand_max_lvl,
            groupcaps = {
                choppy = {times={[3]=minimal.hand_chop}, uses=0,
                          maxlevel=minimal.hand_max_lvl},
                crumbly = {times={[3]=minimal.hand_crum}, uses=0,
                           maxlevel=minimal.hand_max_lvl},
                snappy = {times={[3]=minimal.hand_snap}, uses=0,
                          maxlevel=minimal.hand_max_lvl},
                oddly_breakable_by_hand = {
                    times={
                        [1]=minimal.hand_crum*minimal.t_scale1,
                        [2]=minimal.hand_crum*minimal.t_scale2,
                        [3]=minimal.hand_crum}, uses=0
                },
            },
            damage_groups = {fleshy=minimal.hand_dmg}
        },
        liquids_pointable = true,
        groups = {not_in_creative_inventory = 1, nobones = 1},
})

-- Adds a colorized hand item to the first slot of the main inventory and
-- handles existing items in that slot.
function player_api.add_player_hand(player)
    -- player_api:hand is always in the first slot -> check it
    local inv = player:get_inventory()
    local stack_1 = inv:get_stack("main", 1)
    local name = stack_1:get_name()
    -- new player or respawned or older existing player without a hand?
    if not name:find("player_api:hand", 1, true) then
        local base_texture = player_api.load_base_texture_table(player)
        local handstring = "player_api:hand_"..base_texture["skin"]["color"]

        if inv:is_empty("main") then -- new player or respawn
            inv:set_stack("main", 1, handstring)
        else
            -- must be an existing player who does not yet have a hand
            local player_name = player:get_player_name()
            core.log("info",
                     "player_api:hand for existing player: " .. player_name)
            inv:set_stack("main", 1, handstring)
            core.chat_send_player(player_name, "* * * * * *")
            core.chat_send_player(player_name, S("You were given a hand!"))
            -- try to add the replaced stack somewhere else in main
            if stack_1 and not stack_1:is_empty() then
                local leftover = inv:add_item("main", stack_1)
                if not leftover:is_empty() then
                    -- drop stack and warn player
                    local pos = player:get_pos()
                    core.add_item(vector.new(pos.x,pos.y+1,pos.z), stack_1)
                    core.chat_send_player(player_name,
                                    S("Attention! Some item(s) were dropped."))
                    minimal.warn_inv_full(player)
                end
            end
            core.chat_send_player(player_name, "* * * * * *")
        end
    end
end

