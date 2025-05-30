------------------------------------
--PLANT CRAFTS
--crafts directly using vegetation
--also food processing
-----------------------------------

---------------------------------------

-- Internationalization
local S = tech.S

--Craft items


minetest.register_node(
    "tech:stick", {
        description = S("Stick"),
        drawtype = "nodebox",
        node_box = {
            type ="fixed",
            fixed = {{-0.0625, -0.5, -0.0625, 0.0625, 0.5, 0.0625}},
        },
        --[[ --this might be resuable as a fence, but fails here
            node_box = {
            type = "connected",
            fixed = {{-0.0625, -0.5, -0.0625, 0.0625, 0.5, 0.0625}},
            connect_front = {{-0.0625, -0.0625, -0.5, 0.0625, 0.0625, -0.0625}},
            connect_left = {{-0.5, -0.0625, -0.0625, -0.0625, 0.0625, 0.0625}},
            connect_back = {{-0.0625, -0.0625, 0.0625, 0.0625, 0.0625, 0.5}},
            connect_right = {{0.0625, -0.0625, -0.0625, 0.5, 0.0625, 0.0625}},
            },
            connects_to = {'tech:stick'},
        ]]

        tiles = {"tech_stick.png"},
        stack_max = minimal.stack_max_medium,
        paramtype = "light",
        paramtype2 = "wallmounted",
        climbable = true,
        floodable = true,
        on_flood = function(pos, oldnode, newnode)
            minetest.add_item(pos, ItemStack("tech:stick"))
            pos.y = pos.y + 1
            minetest.after(0, function()
                               minetest.check_for_falling(pos)
            end)
            return false
        end,
        sunlight_propagates = true,
        groups = {choppy=2, dig_immediate=2, flammable=1,
                  attached_node=1, temp_pass = 1, temp_flow = 100},
        override_sneak = true,
        drop = "tech:stick",
        sounds = nodes_nature.node_sound_wood_defaults(),
        on_rightclick = function(pos, node, clicker, itemstack, pointed_thing)
            --Extend or place on top, nothing else. This could be generalized
            -- for other attached nodes
            local itemname = itemstack:get_name()
            if itemname == node.name then
                local flipdir = (node.param2 % 2) * -2 + node.param2 + 1
                local enddir = minetest.wallmounted_to_dir(flipdir)
                local newpos = vector.add(pos,enddir)
                local stickend = minetest.get_node(newpos)
                if stickend.name == "air" then -- extend an existing stick
                    minetest.item_place_node(itemstack, clicker,
                                             {type = "node", under=pos,
                                              above=newpos}, node.param2)
                    return itemstack
                end
            else -- only allow placing things on top of a stick, for support beams etc
                if not pointed_thing then return itemstack end
                local facing = vector.direction(pos, pointed_thing.above)
                if  vector.equals(facing, { x=0, y=1, z=0}) then
                    if itemstack:get_definition().type == "node" then
                        return minetest.item_place_node(itemstack, clicker,
                                                        pointed_thing)
                    end
                end
            end
        end


})

minetest.register_craftitem("tech:grass_fibre",{
                                description = S('Grass Fibre'),
                                inventory_image = "tech_fibrous_bundle.png",
                                stack_max = minimal.stack_max_medium,
                                groups = {flammable=1, fibrous_plant=1}
})


------------------------------------------
--Vegetable Oils


--vegetable oil
minetest.register_craftitem(
    "tech:vegetable_oil", {
        description = S("Vegetable Oil"),
        inventory_image = "tech_vegetable_oil.png",
        stack_max = minimal.stack_max_medium *2,
        groups = {flammable = 1},

        --yes... we are letting you drink cooking oil...
        --...although it is worse than just eating the seeds
        --on_use = function(itemstack, user, pointed_thing)
        --hp_change, thirst_change, hunger_change, energy_change, temp_change, replace_with_item
        --  return HEALTH.use_item(itemstack, user, 0, 0, 8, -32, 0)
        --end,
})



---------------------------------------
--Recipes

--
--Hand crafts (inv)
--

--Sticks from woody plants
crafting.register_recipe({
        type = {"crafting_spot","chopping_block","hand","knife"},
        output = "tech:stick 2",
        items = {{"group:woody_plant","tech:wattle_loose"}},
        level = 1,
        always_known = true,
})
--Grass fibers from fibrous plants
crafting.register_recipe({
        type = {"hand","knife"},
        output = "tech:grass_fibre",
        items = {"group:bundleable_fiber"},
        level = 1,
        always_known = true,
})

--
--mortar and pestle
--

--squeeze oil
crafting.register_recipe({
        type = "mortar_and_pestle",
        output = "tech:vegetable_oil",
        items = {'nodes_nature:vansano_seed 12'},
        level = 1,
        always_known = true,
        sound = {name = "mortar_and_pestle_craft_seed", gain = {1, 2}, pitch = {0.9, 1.15}}
})

crafting.register_recipe({
    type = "mortar_and_pestle",
    output = "tech:vegetable_oil",
    items = {'nodes_nature:maraka_fruit 12'},
    level = 1,
    always_known = true,
    sound = {name = "mortar_and_pestle_craft_seed", gain = {1, 2}, pitch = {0.88, 1.1}}
})
--IB --bulk oil
--IB crafting.register_recipe({
--IB    type = "mortar_and_pestle",
--IB    output = "tech:vegetable_oil 6",
--IB    items = {'nodes_nature:vansano_seed 72'},
--IB    level = 1,
--IB    always_known = true,
--IB })


--
--chopping_block
--

--Sticks from woody plants
--Bulk sticks from woody plants
crafting.register_recipe({
        type = {"chopping_block","knife"},
        output = "tech:stick 24",
        items = {"group:woody_plant 12"},
        level = 1,
        always_known = true,
})

--sticks from tree
crafting.register_recipe({
        type = {"chopping_block","axe"},
        output = "tech:stick 24",
        items = {"group:log"},
        level = 1,
        always_known = true,
})

--sticks from log slabs
crafting.register_recipe({
        type = {"chopping_block","axe"},
        output = "tech:stick 12",
        items = {"group:woodslab"},
        level = 1,
        always_known = true,
})
