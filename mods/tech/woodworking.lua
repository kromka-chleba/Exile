----------------------------------------------------------
--WOODWORKING

-- Internationalisaton
local S = tech.S

-----------------------------------------------------------
--primitive_wooden_chest -- see storage
crafting.register_recipe({
        type = {"chopping_block","axe"},
        output = "tech:primitive_wooden_chest",
        items = {'group:log 4'},
        level = 1,
        always_known = true,
})




-----------------------------------------------------------
--Chest ...see storage

crafting.register_recipe({
        type = "carpentry_bench",
        output = "tech:wooden_chest",
        items = {'tech:iron_fittings 2', 'group:log 4', 'tech:vegetable_oil'},
        level = 1,
        always_known = true,
})


-----------------------------------------------------------
--Ladder
minetest.register_node(
    "tech:wooden_ladder", {
        description = S("Wooden Ladder"),
        drawtype = "nodebox",
        node_box = {
            type = "fixed",
            fixed = {
                {0.3125, -0.5, 0.3125, 0.5, 0.5, 0.5}, -- NodeBox12
                {-0.5, -0.5, 0.3125, -0.3125, 0.5, 0.5}, -- NodeBox13
                {-0.3125, -0.3125, 0.375, 0.3125, -0.1875, 0.4375}, -- NodeBox16
                {-0.3125, 0.1875, 0.375, 0.3125, 0.3125, 0.4375}, -- NodeBox17
            }
        },
        tiles = { "tech_stick.png"},
        stack_max = minimal.stack_max_medium,
        paramtype = "light",
        paramtype2 = "facedir",
        climbable = true,
        sunlight_propagates = true,
        groups = {choppy=2, dig_immediate=2, flammable=2,
                  attached_node=1, temp_pass = 1, ladder = 1},
        drop = "tech:wooden_ladder",
        sounds = nodes_nature.node_sound_wood_defaults(),

        after_place_node = function(pos, placer, itemstack, pointed_thing)
            local node = minetest.get_node(pos)
            local pos_under = {x = pos.x, y = pos.y - 1, z = pos.z}
            local under = minetest.get_node(pos_under)
            if minetest.get_item_group(under.name, "ladder") > 0 then
                minetest.swap_node(pos, {name = node.name, param1 = node.param1,
                                         param2 = under.param2})
            end
        end,
        on_rightclick = function(pos, node, clicker, itemstack, pointed_thing)
            local itemname = itemstack:get_name()
            if minetest.get_item_group(itemname, "ladder") > 0 then
                local pos_over = {x = pos.x, y = pos.y + 1, z = pos.z}
                local over = minetest.get_node(pos_over)
                if over.name == "air" then
                    minetest.place_node(pos_over, {name = itemname})
                    if not minimal.player_in_creative(clicker) then
                        itemstack:take_item()
                    end
                end
            else
                if itemstack:get_definition().type == "node" then
                    return minetest.item_place_node(itemstack, clicker,
                                                    pointed_thing)
                end
            end
        end
})

crafting.register_recipe({
        type = "carpentry_bench",
        output = "tech:wooden_ladder 4",
        items = {'group:log'},
        level = 1,
        always_known = true,
})

-----------------------------------------------------------
--Floor boards
--good flooring for large multi-story buildings


minetest.register_node(
    "tech:wooden_floor_boards", {
        description = S("Wooden Floor Boards"),
        drawtype = "nodebox",
        node_box = {
            type = "fixed",
            fixed = {
                {-0.5, 0.25, -0.5, 0.5, 0.5, 0.5}, -- NodeBox1
                {-0.375, 0, -0.5, -0.125, 0.25, 0.5}, -- NodeBox2
                {0.125, 0, -0.5, 0.375, 0.25, 0.5}, -- NodeBox5
            }
        },
        tiles = {
            "tech_wooden_floor_boards_top.png",
            "tech_wooden_floor_boards_bottom.png",
            "tech_wooden_floor_boards_side.png",
            "tech_wooden_floor_boards_side.png",
            "tech_wooden_floor_boards_front.png",
            "tech_wooden_floor_boards_front.png"
        },
        stack_max = minimal.stack_max_medium,
        paramtype = "light",
        paramtype2 = "facedir",
        groups = {choppy=2, flammable=3},
        sounds = nodes_nature.node_sound_wood_defaults(),

})


crafting.register_recipe({
        type = "carpentry_bench",
        output = "tech:wooden_floor_boards 4",
        items = {'group:log', 'tech:vegetable_oil'},
        level = 1,
        always_known = true,
})

-----------------------------------------------------------
--Wooden Stairs


minetest.register_node(
    "tech:wooden_stairs", {
        description = S("Wooden Stairs"),
        tiles = {"tech_oiled_wood.png"},
        drawtype = "nodebox",
        node_box = {
            type = "fixed",
            fixed = {
                {-0.5, -0.375, -0.5, 0.5, -0.25, -0.25},
                {-0.5, 0.375, 0.25, 0.5, 0.5, 0.5},
                {-0.5, -0.125, -0.25, 0.5, 0, 0},
                {-0.5, 0.125, 0, 0.5, 0.25, 0.25},
                {-0.5, -0.5, -0.4375, 0.5, -0.375, -0.25},
                {-0.5, -0.25, -0.1875, 0.5, -0.125, 0},
                {-0.5, 0, 0.0625, 0.5, 0.125, 0.25},
                {-0.5, 0.25, 0.3125, 0.5, 0.375, 0.5},
            }
        },
        stack_max = minimal.stack_max_medium,
        paramtype = "light",
        paramtype2 = "facedir",
        sunlight_propagates = true,
        groups = {choppy=2, flammable=3},
        sounds = nodes_nature.node_sound_wood_defaults(),

})


crafting.register_recipe({
        type = "carpentry_bench",
        output = "tech:wooden_stairs 4",
        items = {'group:log', 'tech:vegetable_oil'},
        level = 1,
        always_known = true,
})


local ucsigns_available = minetest.get_modpath("ucsigns")
if ucsigns_available then
    print("UCSIGNS AVAILABLE: ",ucsigns_available)
    screwdriver = lever
    local signcolors = {
        tangkal = "#8a7362",
        sasaran = "#977961",
        maraka = "#9e8364",
        kagum = "#8a7957",
        amma = "#f8dba6",
        daoja = "#a7875b",
        jalowiec = "#d9a07b",
        panasee = "#ae8d62",
        tulatula = "#77674a",
    }
    -- sign crafting type
    crafting.register_type("ucsign",
      S("Signs"),
      "ucsigns:wall_sign_exile",
      {name = "nodes_nature_dig_choppy", pitch={0.9,1.3}}
    )
    -- sign groups
    local groups = {
        oddly_breakable_by_hand = 1, ucsign = 1, choppy = 2
    }
    -- make a unique sign for every tree type
    for nname, ndef in pairs(core.registered_nodes) do
        if ndef.groups and ndef.groups.log and ndef.tiles and
          -- if tree variant exists
          core.registered_nodes[ndef.name:gsub("_log","_tree")] then
            -- let's dew it!
            -- remove mod name and _log
            local name = ndef.name:sub(#ndef.mod_origin+2,-5)
            -- sign has issues with 16x16, let's increase it twofold
            local tiles = table.copy(ndef.tiles)
            for ind,tile in ipairs(tiles) do
                -- a bunch of weird calculations I did late at night that don't work upscaled - TPH
                local newtile = "[combine:32x32:"
                for i=1, 4 do
                    local x,y = (i > 2 and 16 or 0), (i%2*16)
                    newtile = newtile..x..","..y.."="..tile
                    newtile = i ~= 4 and newtile..":" or newtile
                end
                tiles[ind] = newtile
            end
            -- permit custom "average_color" (what the node color theoretically should be on a minimap)
            local signcolor = ndef.average_color or signcolors[name] or nil
            name = "exile_"..name
            ucsigns.register_sign(name, signcolor, {
                description = S("@1 Sign", ndef.description),
                tiles = tiles,
                sounds = nodes_nature.node_sound_wood_defaults(),
                groups = groups
            })
            -- ucsigns doesn't properly check and duplicate groups and causes issues
            -- so we'll have to manually add a flag to not be in the creative inventory to declutter
            local standdef = core.registered_nodes["ucsigns:standing_sign_"..name]
            local standgroups = table.copy(groups)
            standgroups.not_in_creative_inventory = 1
            core.override_item(standdef.name, {
                groups = standgroups
            })
            -- register recipe
            crafting.register_recipe({
                    type = "ucsign",
                    output = "ucsigns:wall_sign_"..name,--"ucsigns:wall_sign_exile 1",
                    items = {ndef.name},
                    level = 1,
                    always_known = true,
            })
        -- add ucsigns crafting station to axes and adzes
        elseif ndef.exile_crafting and ndef.exile_crafting.craft_types and ndef.name:match("placed") then
            local craftypes = ndef.exile_crafting.craft_types
            for _,ctype in ipairs(craftypes) do
                if ctype == "axe" then
                    craftypes[#craftypes + 1] = "ucsign"
                    break
                end
            end
        end
    end
    -- oiled sign (previous default)
    ucsigns.register_sign("exile", nil, {
        description = S("Oiled Sign"),
        tiles = { "tech_oiled_wood.png" },
        sounds = nodes_nature.node_sound_wood_defaults(),
        groups = {oddly_breakable_by_hand = 1, ucsign = 1, choppy = 2}
    })
    -- ditto to above disclaimer for why this needs to be done
    local standdef = core.registered_nodes["ucsigns:standing_sign_exile"]
    local standgroups = table.copy(groups)
    standgroups.not_in_creative_inventory = 1
    core.override_item(standdef.name, {
        groups = standgroups
    })
    -- oiled recipe
    crafting.register_recipe({
        type = "ucsign",
        output = "ucsigns:wall_sign_exile 1",
        items = {"group:log 1", "tech:vegetable_oil"},
        level = 1,
        always_known = true,
    })
end
