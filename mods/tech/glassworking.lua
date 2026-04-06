----------------------------------------------------------
--GLASS WORKING


--[[
    >>> making glass
    1800C will fuse sand itself.

    Soda lime glass
    Soda ash. - melting agent (1200C)
    Sand -vitrifying
    Calcium - stabilizing (potentially in the sand)

    Two types of glass - green and clear

    Green - made from ash and sand. Ash contains potash/soda ash and lime,
    but also iron impurities that color the glass green.
    Good for things where clarity doesn't matter, like bottler
    Clear - made from refined potash (pearl ash), lime and sand. More expensive,
    as have to work to refine potash. Good for windows.

    Potash - in this case get from wood ash.
    Process:
    1. Soak in water
    2. Put water into pot
    3. Evaporate water to get potash (still with impurities, makes green glass)
    4. Roast potash in kiln to get pearl ash

    >>>make things from glass:
    Reheat so it is workable, then shape.
    Small glass workshop furnace.

    Vessels: glass blowing

    Panes: cast on to an iron tray, then polished. Only get small panes.


]]
-----------------------------------------------------------

-- Internationalization
local S = tech.S

local c_alpha = EXILE.compat_alpha

-- Pre-roast  functions
local function set_roast(pos, length, interval)
    -- and firing count
    local meta = minetest.get_meta(pos)
    meta:set_int("roast", length)
    --check heat interval
    minetest.get_node_timer(pos):start(interval)
end



local function roast(pos, selfname, name, heat)
    local meta = minetest.get_meta(pos)
    local roasting = meta:get_int("roast")

    --check if wet stop
    if climate.get_rain(pos) or
        minetest.find_node_near(pos, 1, {"group:water"}) then
        return true
    end

    --exchange accumulated heat
    climate.heat_transfer(pos, selfname)

    --check if above firing temp
    local temp = climate.get_point_temp(pos)
    local fire_temp = heat

    if roasting <= 0 then
        --finished firing
        EXILE.switch_node(pos, name)
        if minetest.get_item_group(name,"heatable") > 0 then
            meta:set_float("temp", temp)
        end
        minetest.check_for_falling(pos)
        return false
    elseif temp < fire_temp then
        --not lit yet
        return true
    elseif temp >= fire_temp then
        --do firing
        meta:set_int("roast", roasting - 1)
        return true
    end

end

-- Pane Casting function
local function pane_cast_check(pos)

    local pbelow = {x = pos.x, y = pos.y - 1, z = pos.z}
    if minetest.get_node(pbelow).name == "tech:pane_tray" and
        climate.get_point_temp(pos) >= 1800 then
        -- Melting temperature of glass is approx 1800 C
        local name = minetest.get_node(pos).name
        if name == "tech:green_glass_ingot" then
            minetest.set_node(pos, {name = "air"})
            minetest.swap_node(pbelow, {name = "tech:pane_tray_green"})
            minetest.sound_play("tech_boil", {pos = pos, max_hear_distance = 8,
                                              gain = 1})
            return true
        elseif name == "tech:clear_glass_ingot" then
            minetest.set_node(pos, {name = "air"})
            minetest.swap_node(pbelow, {name = "tech:pane_tray_clear"})
            minetest.sound_play("tech_boil", {pos = pos,
                                              max_hear_distance = 8, gain = 1})
            return true
        end
    end
    return false
end


-- Green glass

-- Mix - sand and ash 50/50
minetest.register_node(
    "tech:green_glass_mix",
    {
        description = S("Green Glass Sand Mix"),
        tiles = {"tech_sand_mix.png"},
        stack_max = EXILE.stack_max_bulky *4,
        paramtype = "light",
        groups = {crumbly = 3, falling_node = 1, heatable = 20},
        sounds = nodes_nature.node_sound_sand_defaults(),
        on_construct = function(pos)
            --length(i.e. difficulty of firing), interval for checks (speed)
            set_roast(pos, 40, 10)
        end,
        on_timer = function(pos, _elapsed)
            --finished product, length, heat, smelt
            return roast(pos, "tech:green_glass_mix",
                         "tech:green_glass_ingot", 1500)
        end,
})

-- Finished Products
-- Glass ingot - 1/4 block
minetest.register_node(
    "tech:green_glass_ingot", {
        description = S("Green Glass Ingot"),
        tiles = {"tech_green_glass.png"},
        inventory_image = "tech_glass_ingot_green_icon.png",
        drawtype = "nodebox",
        node_box = {
            type = "fixed",
            fixed = {-0.3, -0.5, -0.3, 0.3, -0.1, 0.3},
        },
        stack_max = EXILE.stack_max_bulky * 4,
        paramtype = "light",
        groups = {cracky = 3, oddly_breakable_by_hand = 3,
                  falling_node = 1, temp_pass = 1, heatable = 20},
        sounds = tech.node_sound_glass_defaults(),
        use_texture_alpha = c_alpha.blend,
        sunlight_propagates = true,
        on_construct = function(pos)
            climate.heat_transfer(pos, "tech:green_glass_ingot")
            minetest.get_node_timer(pos):start(20)
        end,
        on_timer = function(pos)
            if pane_cast_check(pos) then
                return false -- end the timer
            else
                return true
            end
        end,
})

-- Crafts
-- Mix sand and ash 50/50
crafting.register_recipe({
        type = "hammer",
        output = "tech:green_glass_mix 2",
        items = {'tech:wood_ash_block 1', 'nodes_nature:sand 1'},
        level = 1,
        always_known = true,
})

-- Clear Glass

-- Potash

minetest.register_node(
    "tech:potash_block", {
        description = S("Potash Block"),
        tiles = {"tech_potash.png"},
        stack_max = EXILE.stack_max_bulky,
        groups = {crumbly = 3, falling_node = 1, fertilizer = 1},
        sounds = nodes_nature.node_sound_dirt_defaults(),
})


minetest.register_node(
    "tech:potash", {
        description = S("Potash"),
        tiles = {"tech_potash.png"},
        stack_max = EXILE.stack_max_bulky *2,
        drawtype = "nodebox",
        node_box = {
            type = "fixed",
            fixed = {-0.5, -0.5, -0.5, 0.5, 0, 0.5},
        },
        groups = {crumbly = 3, falling_node = 1, fertilizer = 1},
        sounds = nodes_nature.node_sound_dirt_defaults(),
})

local post_alpha = 140

-- Potash solution (More like lye in this case)
minetest.register_node(
    "tech:potash_source", {
        description = S("Potash Solution Source"),
        drawtype = "liquid",
        tiles = {"tech_potash.png"},
        --      use_texture_alpha = "blend",
        paramtype = "light",
        walkable = false,
        pointable = false,
        diggable = false,
        buildable_to = true,
        is_ground_content = false,
        drop = "",
        drowning = 1,
        liquidtype = "source",
        liquid_alternative_flowing = "tech:potash_flowing",
        liquid_alternative_source = "tech:potash_source",
        liquid_viscosity = 1,
        liquid_range = 2,
        liquid_renewable = false,
        post_effect_color = {a = post_alpha, r = 30, g = 60, b = 90},
        damage_per_second = 2,
        groups = {water = 2, cools_lava = 1, puts_out_fire = 1},
        sounds = nodes_nature.node_sound_water_defaults(),
})


minetest.register_node(
    "tech:potash_flowing", {
        description = S("Flowing Potash Solution"),
        drawtype = "flowingliquid",
        tiles = {"tech_potash.png"},
        special_tiles = {"tech_potash.png",
                         "tech_potash.png",
                         "tech_potash.png",
                         "tech_potash.png",
                         "tech_potash.png",
                         "tech_potash.png",},
        use_texture_alpha = c_alpha.blend,
        paramtype = "light",
        paramtype2 = "flowingliquid",
        walkable = false,
        pointable = false,
        diggable = false,
        buildable_to = true,
        is_ground_content = false,
        liquid_move_physics = false,
        move_resistance = 0,
        drop = "",
        drowning = 1,
        liquidtype = "flowing",
        liquid_range = 2,
        liquid_alternative_flowing = "tech:potash_flowing",
        liquid_alternative_source = "tech:potash_source",
        liquid_viscosity = 1,
        liquid_renewable = false,
        post_effect_color = {a = post_alpha, r = 30, g = 60, b = 90},
        damage_per_second = 1,
        groups = {water = 2, not_in_creative_inventory = 1,
                  puts_out_fire = 1, cools_lava = 1},
        sounds = nodes_nature.node_sound_water_defaults(),
})

--Register liquids
liquid_store.register_liquid("tech:potash_source", -- source
    {
        flowing = "tech:potash_flowing", -- flowing
        force_renew = false, -- do not renew if I take from a potash source
        groups = {"potash"} -- groups list
    }
)

-- Solution in pot (clay and wooden)
for _, mat in pairs ({"clay", "wooden"}) do
    local def = {
        source = "tech:potash_source",
        empty = "tech:".. mat .. "_water_pot",
        groups = {dig_immediate = 2},
        tiles = tech.get_stored_liquid_tiles(mat, "pot",
                                "^tech_pot_potash.png"),
        -- specific setting in liquid_store registration:
        node_box = "container" -- "use the container's node_box'"
    }
    if mat == "clay" then
        def.description = S("Clay Water Pot with Potash Solution")
        def.groups["pottery"] = 1
    elseif mat == "wooden" then
        def.description = S("Wooden Water Pot with Potash Solution")
        def.groups["flammable"] = 3
        def.sounds = nodes_nature.node_sound_wood_defaults() -- not sure I need it
    end
    liquid_store.register_stored_liquid("tech:"..mat.. "_water_pot_potash",def)
end

-- Soak Ash
local function potash_soak_check(pos, _node)

    local p_water = minetest.find_node_near(pos, 1,
                                            {"nodes_nature:freshwater_source"})
    if p_water then
        local p_name = minetest.get_node(p_water).name
        --check water type. Salt wouldn't work probably
        local water_type = minetest.get_item_group(p_name, "water")
        if water_type == 1 then
            minetest.set_node(pos, {name = "tech:potash_source"})
            minetest.set_node(p_water, {name = "air"})
            minetest.sound_play("tech_boil",
                                {pos = pos,
                                 max_hear_distance = 8, gain = 1})
        elseif water_type == 2 then
            return false
        end
    end
end

minetest.register_abm(
    {
        label = "Ash Dissolve",
        nodenames = {"tech:wood_ash_block"},
        neighbours = {"nodes_nature:freshwater_source"},
        interval = 15,
        chance = 1,
        action = function(...)
            potash_soak_check(...)
        end
})

-- Evaporation result; water is gone, just potash left

minetest.register_node(
    "tech:dry_potash_pot", {
        description = S("Clay Water Pot With Potash"),
        tiles = {
            "tech_pottery.png^tech_pot_empty.png",
            "tech_pottery.png",
            "tech_pottery.png",
            "tech_pottery.png",
            "tech_pottery.png",
            "tech_pottery.png"
        },
        drawtype = "nodebox",
        stack_max = EXILE.stack_max_bulky,
        paramtype = "light",
        node_box = {
            type = "fixed",
            fixed = {
                {-0.25, 0.375, -0.25, 0.25, 0.5, 0.25}, -- NodeBox1
                {-0.375, -0.25, -0.375, 0.375, 0.3125, 0.375}, -- NodeBox2
                {-0.3125, -0.375, -0.3125, 0.3125, -0.25, 0.3125}, -- NodeBox3
                {-0.25, -0.5, -0.25, 0.25, -0.375, 0.25}, -- NodeBox4
                {-0.3125, 0.3125, -0.3125, 0.3125, 0.375, 0.3125}, -- NodeBox5
            }
        },
        groups = {dig_immediate = 3, pottery = 1, temp_pass = 1, falling_node = 1},
        sounds = nodes_nature.node_sound_stone_defaults(),
        drop = {
            max_items = 2,
            items = {
                {items = {"tech:potash"}},
                {items = {"tech:clay_water_pot"}},
            }
        }

})


-- Potash evaporation
minetest.override_item(
    "tech:clay_water_pot_potash",
    {
        on_construct = function(pos)
            minetest.get_node_timer(pos):start(math.random(10,20))
        end,
        on_timer = function(pos, _elapsed)
            if climate.get_point_temp(pos) > 100 then
                minetest.swap_node(pos, {name = "tech:dry_potash_pot"})
                return false
            end

            return true
        end,

})
minetest.override_item("tech:wooden_water_pot_potash",
{
	on_construct = function(pos)
		minetest.get_node_timer(pos):start(math.random(10,20))
	end,
        on_burn = function(pos)
            minetest.swap_node(pos, {name = "tech:potash"})
        end,
	on_timer = function(pos, _elapsed)
		if climate.get_point_temp(pos) > 100 then
			minetest.swap_node(pos, {name = "tech:potash"})
			return false
		end

		return true
	end,

})

-- The actual glassmaking... finally

-- Mix - sand, potash and lime
minetest.register_node(
    "tech:clear_glass_mix",
    {
        description = S("Clear Glass Sand Mix"),
        tiles = {"tech_sand_mix.png"},
        stack_max = EXILE.stack_max_bulky *4,
        paramtype = "light",
        groups = {crumbly = 3, falling_node = 1, heatable = 20},
        sounds = nodes_nature.node_sound_sand_defaults(),
        on_construct = function(pos)
            --length(i.e. difficulty of firing), interval for checks (speed)
            set_roast(pos, 40, 10)
        end,
        on_timer = function(pos, _elapsed)
            --finished product, length, heat, smelt
            return roast(pos, "tech:clear_glass_mix",
                         "tech:clear_glass_ingot", 1500)
        end,
})

-- Finished Products
-- Glass ingot - 1/4 block
minetest.register_node(
    "tech:clear_glass_ingot", {
        description = S("Clear Glass Ingot"),
        tiles = {"tech_clear_glass.png"},
        inventory_image = "tech_glass_ingot_clear_icon.png",
        drawtype = "nodebox",
        node_box = {
            type = "fixed",
            fixed = {-0.3, -0.5, -0.3, 0.3, -0.1, 0.3},
        },
        stack_max = EXILE.stack_max_bulky * 4,
        paramtype = "light",
        groups = {cracky = 3, oddly_breakable_by_hand = 3,
                  falling_node = 1, temp_pass = 1, heatable = 20},
        sounds = tech.node_sound_glass_defaults(),
        use_texture_alpha = c_alpha.blend,
        sunlight_propagates = true,
        on_construct = function(pos)
            minetest.get_node_timer(pos):start(20)
        end,
        on_timer = function(pos)
            climate.heat_transfer(pos, "tech:clear_glass_ingot")
            if pane_cast_check(pos) then
                return false -- end the timer
            else
                return true
            end
        end,
})

-- Crafts
-- Mix sand and potash and lime approx 70/15/15 (1/2 + 1/4 sand, 1/8 pearlash, 1/8 lime )
crafting.register_recipe({
        type = "hammer",
        output = "tech:clear_glass_mix 8",
        items = {'tech:potash 1', 'tech:quicklime 1', 'nodes_nature:sand 6'},
        level = 1,
        always_known = true,
})

-- Pane casting tray - heat up a glass ingot above it to cast a pane
minetest.register_node(
    "tech:pane_tray",
    {
        description = S("Pane Casting Tray"),
        tiles = {"tech_iron.png"},
        drawtype = "nodebox",
        node_box =
            {
                type = "fixed",
                fixed = {
                    {-0.5, -0.5, -0.5, 0.5, -0.4, 0.5},
                    {-0.5, -0.4, -0.5, -0.4, -0.3, 0.5},
                    {0.5, -0.4, -0.5, 0.4, -0.3, 0.5},
                    {-0.5, -0.4, -0.5, 0.5, -0.3, -0.4},
                    {-0.5, -0.4, 0.5, 0.5, -0.3, 0.4}
                }

            },
        stack_max = EXILE.stack_max_bulky * 2,
        sounds = tech.node_sound_metal_hollow_defaults(),
        paramtype = "light",
        paramtype2 = "facedir",
        groups = {cracky = 3, oddly_breakable_by_hand = 3, falling_node = 1},
        sunlight_propagates = true,
})

-- Trays with glass panes
minetest.register_node(
    "tech:pane_tray_green",
    {
        description = S("Pane Casting Tray With Green Glass Pane"),
        tiles = {"tech_tray_green.png", "tech_iron.png", "tech_iron.png",
                 "tech_iron.png", "tech_iron.png", "tech_iron.png"},
        drawtype = "nodebox",
        node_box =
            {
                type = "fixed",
                fixed = {
                    {-0.5, -0.5, -0.5, 0.5, -0.3, 0.5},
                    {-0.5, -0.4, -0.5, -0.4, -0.3, 0.5},
                    {0.5, -0.4, -0.5, 0.4, -0.3, 0.5},
                    {-0.5, -0.4, -0.5, 0.5, -0.3, -0.4},
                    {-0.5, -0.4, 0.5, 0.5, -0.3, 0.4}
                }

            },
        stack_max = EXILE.stack_max_bulky * 2,
        sounds = tech.node_sound_metal_hollow_defaults(),
        paramtype = "light",
        paramtype2 = "facedir",
        groups = {dig_immediate = 3, falling_node = 1},
        sunlight_propagates = true,
        on_dig = function(pos, _node, digger)
            minetest.sound_play("tech_glass_dug",{
                                    pos = pos,
                                    gain = 1,
                                    max_hear_distance = 10
            })
            local inv = digger:get_inventory()
            if inv:room_for_item("main", "tech:pane_green") then
                inv:add_item("main", "tech:pane_green")
                minetest.swap_node(pos, {name = "tech:pane_tray"})
            elseif not EXILE.stop_on_inv_full(digger) then
                minetest.add_item(pos, "tech:pane_green")
                minetest.swap_node(pos, {name = "tech:pane_tray"})
            end
        end,

})

minetest.register_node(
    "tech:pane_tray_clear",
    {
        description = S("Pane Casting Tray With Clear Glass Pane"),
        tiles = {"tech_tray_clear.png", "tech_iron.png", "tech_iron.png",
                 "tech_iron.png", "tech_iron.png", "tech_iron.png"},
        drawtype = "nodebox",
        node_box =
            {
                type = "fixed",
                fixed = {
                    {-0.5, -0.5, -0.5, 0.5, -0.3, 0.5},
                    {-0.5, -0.4, -0.5, -0.4, -0.3, 0.5},
                    {0.5, -0.4, -0.5, 0.4, -0.3, 0.5},
                    {-0.5, -0.4, -0.5, 0.5, -0.3, -0.4},
                    {-0.5, -0.4, 0.5, 0.5, -0.3, 0.4}
                }

            },
        stack_max = EXILE.stack_max_bulky * 2,
        sounds = tech.node_sound_metal_hollow_defaults(),
        paramtype = "light",
        paramtype2 = "facedir",
        groups = {dig_immediate = 3, falling_node = 1},
        sunlight_propagates = true,
        on_dig = function(pos, _node, digger)
            minetest.sound_play("tech_glass_dug",{
                                    pos = pos,
                                    gain = 1,
                                    max_hear_distance = 10
            })
            local inv = digger:get_inventory()
            if inv:room_for_item("main", "tech:pane_clear") then
                inv:add_item("main", "tech:pane_clear")
                minetest.swap_node(pos, {name = "tech:pane_tray"})
            elseif not EXILE.stop_on_inv_full(digger) then
                minetest.add_item(pos, "tech:pane_clear")
                minetest.swap_node(pos, {name = "tech:pane_tray"})
            end
        end,

})

-- Crafts
crafting.register_recipe({
        type = "anvil",
        output = "tech:pane_tray",
        items = {'tech:iron_ingot 2'},
        level = 1,
        always_known = true,
})

-- Stuff made from glass

-- Panes - raw, cast from glass with no framing
minetest.register_node(
    "tech:pane_green",
    {
        description = S("Green Glass Pane"),
        tiles = {"tech_green_glass.png"},
        inventory_image = "tech_green_pane_icon.png",
        drawtype = "nodebox",
        node_box =
            {
                type = "fixed",
                fixed = {{-1/2 + 1/10, -1/2, -1/32, 1/2 - 1/10, 1/2 - 2/10, 1/32}}, -- Modified from xpanes
            },
        stack_max = EXILE.stack_max_medium * 2,
        paramtype = "light",
        paramtype2 = "facedir",
        groups = {cracky = 3, oddly_breakable_by_hand = 3, falling_node = 1},
        use_texture_alpha = c_alpha.blend,
        sunlight_propagates = true,
        sounds = tech.node_sound_glass_defaults(),
        after_place_node = EXILE.protection_after_place_node,
})

minetest.register_node(
    "tech:pane_clear",
    {
        description = S("Clear Glass Pane"),
        tiles = {"tech_clear_glass.png"},
        inventory_image = "tech_clear_pane_icon.png",
        drawtype = "nodebox",
        node_box =
            {
                type = "fixed",
                fixed = {{-1/2 + 1/10, -1/2, -1/32, 1/2 - 1/10, 1/2 - 2/10, 1/32}}, -- Modified from xpanes
            },
        stack_max = EXILE.stack_max_medium * 2,
        paramtype = "light",
        paramtype2 = "facedir",
        groups = {cracky = 3, oddly_breakable_by_hand = 3, falling_node = 1},
        use_texture_alpha = c_alpha.blend,
        sunlight_propagates = true,
        sounds = tech.node_sound_glass_defaults(),
        after_place_node = EXILE.protection_after_place_node,
})

-- Windows - glass panes with framing

minetest.register_node(
    "tech:window_green",
    {
        description = S("Green Glass Window"),
        tiles = {"tech_oiled_wood.png", "tech_oiled_wood.png",
                 "tech_oiled_wood.png", "tech_oiled_wood.png",
                 "tech_green_glass_window.png", "tech_green_glass_window.png"},
        inventory_image = "tech_green_glass_window.png^[noalpha",
        drawtype = "nodebox",
        node_box =
            {
                type = "fixed",
                fixed = {{-1/2, -1/2, -1/32, 1/2, 1/2, 1/32}}, -- From xpanes
            },
        stack_max = EXILE.stack_max_medium * 2,
        paramtype = "light",
        paramtype2 = "facedir",
        groups = {cracky = 3, oddly_breakable_by_hand = 3, flammable = 15},
        use_texture_alpha = c_alpha.blend,
        sunlight_propagates = true,
        sounds = tech.node_sound_glass_defaults(),
        after_place_node = EXILE.protection_after_place_node,
        on_burn = function(pos)
            minetest.add_item(pos, ItemStack("tech:pane_green"))
            minetest.set_node(pos, {name = 'air'})
            minetest.check_for_falling(pos)
        end,
})

minetest.register_node(
    "tech:window_clear",
    {
        description = S("Clear Glass Window"),
        tiles = {"tech_oiled_wood.png", "tech_oiled_wood.png",
                 "tech_oiled_wood.png", "tech_oiled_wood.png",
                 "tech_clear_glass_window.png", "tech_clear_glass_window.png"},
        inventory_image = "tech_clear_glass_window.png^[noalpha",
        drawtype = "nodebox",
        node_box =
            {
                type = "fixed",
                fixed = {{-1/2, -1/2, -1/32, 1/2, 1/2, 1/32}}, -- From xpanes
            },
        stack_max = EXILE.stack_max_medium * 2,
        paramtype = "light",
        paramtype2 = "facedir",
        groups = {cracky = 3, oddly_breakable_by_hand = 3, flammable = 15},
        use_texture_alpha = c_alpha.blend,
        sunlight_propagates = true,
        sounds = tech.node_sound_glass_defaults(),
        after_place_node = EXILE.protection_after_place_node,
        on_burn = function(pos)
            minetest.add_item(pos, ItemStack("tech:pane_clear"))
            minetest.set_node(pos, {name = 'air'})
            minetest.check_for_falling(pos)
        end,
})

-- Windows from oiled wood frames and glass panes
--TODO: if the glass furnace is ever replaced by more sophisiticated glass working then
-- all wood framed glass crafts would make more sense to be in carpentry
-- currently in glass furnace because removing them makes the glass furnace a silly thing with
-- almost no crafts
crafting.register_recipe({
        type = "glass_furnace",
        output = "tech:window_green 4",
        items = {'group:log', 'tech:vegetable_oil', 'tech:pane_green 4'},
        level = 1,
        always_known = true,
})
crafting.register_recipe({
        type = "glass_furnace",
        output = "tech:window_clear 4",
        items = {'group:log', 'tech:vegetable_oil', 'tech:pane_clear 4'},
        level = 1,
        always_known = true,
})

--TODO: recycle doors back into windows and fittings somehow?.
-- Don't want to add them as options into window as should also get iron back.
