-- nodes for megamorph

minetest.register_node(
    "megamorph:vent_open", {
        drawtype = "airlike",
        is_ground_content = false,
        sunlight_propagates = true,
        walkable = false,
        pointable = false,
        floodable = true,
        buildable_to = true,
        paramtype = "light",
        on_flood = function(pos, oldnode, newnode)
            minetest.set_node(pos, {name = "megamorph:vent_closed"})
            return true
        end,
})

minetest.register_node(
    "megamorph:vent_closed", {
        drawtype = "nodebox",
        node_box =
            {
                type = "fixed",
                fixed = {
                    {-0.5, 0.5, -0.5, 0.5, 0.4, 0.5},
                }
            },
        tiles = {"tech_iron.png"},
        is_ground_content = false,
        sunlight_propagates = false,
        walkable = true,
        pointable = true,
        floodable = false,
        groups = {crumbly = 2},
        on_dig = function(pos, node, digger)
            minetest.remove_node(pos)
            minetest.sound_play("xpanes_steel_bar_door_open",
                                { pos = pos })
            return false
        end,
        on_punch = function(pos, node, puncher, pointed_thing)
            local above = minetest.get_node(vector.add(pos, vector.new(0,1,0)))
            if above.name == "air" then
                minetest.set_node(pos, {name = "megamorph:vent_open"})
                minetest.sound_play("xpanes_steel_bar_door_open",
                                    { pos = pos })
            end
        end,
})
