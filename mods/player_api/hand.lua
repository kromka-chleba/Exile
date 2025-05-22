-- The hand
minetest.register_item(
    ":", {
        type = "none",
        wield_image = "wieldhand.png",
        wield_scale = {x=1,y=1,z=2.5},
        liquids_pointable = true,
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
            damage_groups = {fleshy=minimal.hand_dmg},
        },
})
