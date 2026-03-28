--------------------------------------------------------------------------------
-- Tutorial nodes

local S = minetest.get_translator("tutorial_exile")

minetest.register_node(
    "tutorial_exile:invisible_wall", {
        description = "Tutorial boundary wall",
        tiles = {"climate_air.png"},
        drawtype = "airlike",
        paramtype = "light",
        sunlight_propagates = true,
        pointable = false,
        walkable = true,
        buildable_to = false,
        floodable = false,
        wield_image = "tech_trapdoor_wattle_side.png",
        inventory_overlay = "tech_trapdoor_wattle_side.png",
        groups = {temp_pass = 1, not_in_creative_inventory = 1},
        post_effect_color = {a = 5, r = 254, g = 254, b = 254},
        color = {a=0, r=254, g = 254, b = 254},
        use_texture_alpha = "blend",
})


minetest.register_ore({
        ore_type        = "stratum",
        ore             = "tutorial_exile:invisible_wall",
        wherein         = {"air"},
        clust_scarcity  = 1,
        y_max           = 9000,
        y_min           = 9000,
        stratum_thickness = 1,
})

minetest.register_node(
    'tutorial_exile:wall', {
        description = 'Tutorial wall',
        tiles = {
            "tut_wall.png",
        },
        groups = { not_in_creative_inventory = 1 },
})

minetest.register_node(
    'tutorial_exile:iron_wall', {
        description = 'Tutorial iron wall',
        tiles = {{
                name = "[combine:32x16:0,0=tech_iron.png:16,0=tech_iron.png",
                align_style = "world",
                scale = 2
        }},
        drawtype = "nodebox",
        node_box = { type = "fixed",
                    fixed = {-0.5,-0.5,-0.5,
                             00.5, 1.5, 0.5 } },
        groups = { not_in_creative_inventory = 1 },
})

if minetest.is_creative_enabled() then
    minetest.override_item("tutorial_exile:invisible_wall", {
                               drawtype = "glasslike",
                               pointable = true,
                               diggable = true,
                               groups = {crumbly = 1, cracky = 3,
                                         temp_pass = 1},
    })
    minetest.override_item('tutorial_exile:wall', {
                               groups = {crumbly = 1, cracky = 3},
    })
    minetest.override_item('tutorial_exile:iron_wall', {
                               groups = {crumbly = 1, cracky = 3},
    })
end


local lpname = "tut_lighted_path"
local lpdef = {
    description = 'Lighted Path',
    tiles = { {
            name = lpname,
            animation = { type = "vertical_frames",
                          aspect_w = 1,
                          aspect_h = 1,
                          length = 3 }
    }},
    sounds = nodes_nature.node_sound_stone_defaults(),
    groups = { not_in_creative_inventory = 1,
               oddly_breakable_by_hand = 1},
    after_place_node = function(pos, placer, itemstack, pointed_thing)
        local name = itemstack:get_name()
        local pfx = "tutorial_exile:tut_lighted_path"
        local num = tonumber((name:gsub(pfx,"")))
        num = num +1 if num == 9 then num = 1 end
        itemstack:replace(pfx..tostring(num))
    end,
}
if minetest.is_creative_enabled() then lpdef.diggable = true end
for i = 1, 8 do
    local def = table.copy(lpdef)
    local name = lpname..tostring(i)
    def.tiles[1].name = name..".png"
    if i == 1 and minetest.is_creative_enabled() then
        def.groups.not_in_creative_inventory = 0
    end
    minetest.register_node("tutorial_exile:"..name, def)
end

--- Inactive dummy nodes

minetest.register_node(
    "tutorial_exile:sand", {
        description = "Sand",
        tiles = {"nodes_nature_sand.png"
        },
        sounds = nodes_nature.node_sound_sand_defaults(),
        groups = { crumbly = 3, falling_node = 1, puts_out_fire = 1,
                   not_in_creative_inventory = 1 }
})


minetest.register_node(
    "tutorial_exile:wet_silt", {
        description = "Wet Silt",
        tiles = {"nodes_nature_silt.png^nodes_nature_mud.png",
                 "nodes_nature_silt.png^nodes_nature_mud.png",
                 "nodes_nature_silt.png^nodes_nature_mud.png"
        },
        sounds = { footstep = {name = "nodes_nature_dirt_footstep", gain = 0.4},
                   dig = {name = "nodes_nature_dig_crumbly", gain = 1.0},
                   dug = {name = "nodes_nature_dirt_footstep", gain = 1.0}
                 },
        groups = { crumbly = 3, falling_node = 1, puts_out_fire = 1,
                   not_in_creative_inventory = 1 }
})

minetest.register_node(
    "tutorial_exile:demo_fire", {
        description = S("Demonstration fire"),
        drawtype = "nodebox",
        node_box = {
            type = "fixed",
            fixed = {-0.5, -0.5, -0.5, 0.5, 0, 0.5},
        },
        tiles = {"tech_wood_fire_unlit.png"},
        paramtype = "light",
        groups = { flammable = 1 },
        sounds = nodes_nature.node_sound_wood_defaults(),
        on_ignite = nil -- see the override in shelter.lua
})


--- Door and switch

ncrafting.register_switch(
    "tutorial_exile:basalt_hand_switch", {
        description = "A hand carved in stone",
        paramtype2 = "facedir",
        tiles={
            "nodes_nature_basalt.png",
            "nodes_nature_basalt.png",
            "nodes_nature_basalt.png^tech_paint_lw_hand.png",
            "nodes_nature_basalt.png^tech_paint_lw_hand.png",
            "nodes_nature_basalt.png",
            "nodes_nature_basalt.png",
        },
        groups = { switch = 1, not_in_creative_inventory = 1 },
        _switch_sound = "exile_switch_ancient",
        _switch_sound_params = { gain = 0.5, max_hear_distance = 8 },
})


minetest.register_node(
    'tutorial_exile:open_door', {
        description = 'Tutorial Doorway',
        drawtype = "airlike",
        paramtype = "light",
        sunlight_propagates = true,
        pointable = false,
        walkable = false,
        buildable_to = false,
        floodable = false,
        groups = { frobbable = 1, not_in_creative_inventory = 1 },
        _on_frob = function(pos)
            minetest.swap_node(pos, {name="tutorial_exile:closed_door"})
        end
})
minetest.register_node(
    'tutorial_exile:closed_door', {
        description = 'Tutorial force field',
        tiles = {
            { name = "metal_plasma.png", backface_culling = true }
        },
        drawtype = "glasslike",
        groups = { frobbable = 1, not_in_creative_inventory = 1 },
        light_source = 6,
        use_texture_alpha = "blend",
        _on_frob = function(pos)
            minetest.swap_node(pos, {name = "tutorial_exile:open_door"})
        end
})

if minetest.is_creative_enabled() then
    minetest.override_item(
        "tutorial_exile:basalt_hand_switch",
        {
            groups = { switch = 1, crumbly = 1, cracky = 3 },
    })
    minetest.override_item(
        "tutorial_exile:open_door",
        {
            groups = { frobbable = 1, crumbly = 1, cracky = 3 },
    })
end

--- Info boxes

-- A clickable node that displays a preset, translatable text shown below,
--  according to the label set for the node's meta key "tutinfo_text"
-- Alternately, can be used to display any text (without translation) that is
--  stored in the node as "tutinfo_rawtext"

local info = { -- #TODO: set up locales, template.txt etc
    ["dig_key"] = "^  "..S("Press the dig button to pick up or strike things."),
    ["place_key"] = "v  "..S("Press the place button to put things down."),
    ["use_key"] = "◊  "..S("Press the use button to activate items and nodes."..
                           "@n @n This is E by default on PC, AUX1 or sprint on mobile."),
    ["zoom_key"] = S("Press the zoom key to see the name of what "..
                     "you're looking at. @n This is Z by default on PC, "..
                     "and the binoculars or magnifying lens on mobile."),
    ["crawl"] = S("Double-tap sneak to crouch and get through small spaces.@n"..
                  "@nIf server lag makes this hard, you can use the"..
                  " /crouch command, or install exile_csm, the "..
                  "client-side mod to handle controls locally."),
    ["movement"] = S("Loss of energy affects move and jump rate."),
    ["torch"] = S("Drop a torch to see what's below."),
    ["shelter"] = S("A shelter needs something solid over your head.@n"..
                    "Once completed, this roof will shield against hot or "..
                    "cold weather."),
    ["shelter_bed"] = S("Build a bed in a sheltered place to restore energy.@n"
                        .."Better beds restore it faster.@n@n")..
                        S("This is a very poor bed and shelter."),
    ["shelter_fire"] = S("Fires create hot air, which will drift away unless "..
                         "contained.@n"..
                         "It is normally invisible, but is shown here."),
    ["shelter_fire2"] = S("Keep fires away from water, muddy ground, and "..
                          "anything that can catch on fire."),
    ["crafting1"] = S("Dig this plant and right click with an empty hand "..
                      "to open the crafting menu. "..
                      "Craft sticks from the plants."),
    ["crafting2"] = S("Look in the tools tab and craft a digging stick, "..
                      "which can break the clay blocking the door." ),
    ["crafting3"] = S("A flat surface to work on allows more crafts.@n"..
                      "Craft an adze to remove the log that's in the way."),
    ["crafting4"] = S("More crafts come with tools and stations.@n"..
                      "Craft iron ingots for an iron pick to cut the "..
                      "stone covering the exit"),
    ["crafting5"] = S("You'll need a ladder here. Put down your adze to make "..
                      "sticks from a log, then combine with the fiber from "..
                      "the pot. The ladder is made in the weaving tab of "..
                      "hand crafting."),
    ["crafting6"] = S("Some crafts need to be done by cooking with fire "..
                      "or soaking things under a liquid." ),
    ["spirit1"] = S("Exile is a challenging game. Failure is normal, and "..
                    "a part of the fun!"),
    ["spirit2"] = S("Can you jump the gap?"),
    ["spirit3"] = S("Do you want to try again?"),
    ["spirit4"] = S("What if you tried a different method?"),
    ["spirit5"] = S("You might not succeed at what you were planning, "..
                    "but you might find another way!"),
    ["spirit6"] = S("New players will typically die several times before "..
                    "learning how to survive. Try to enjoy your character's "..
                    "adventure, even if it ends in disaster."),
    ["spirit7"] = S("Be prepared to experiment, explore, and try, try again!"),
    ["spirit8"] = S("Good Luck! The tutorial is over now. You are on your own."),
}

local function display_info(pos, player)
    if not player or not minetest.is_player(player) then return end
    local meta = minetest.get_meta(pos)
    local itext = meta:get("tutinfo_text")
    if itext == "delete" then
        minetest.set_node(pos, { name = "air" })
        return
    end
    itext = info[itext] or "INFO"
    if itext == "INFO" and meta:contains("tutinfo_rawtext") then
        itext = meta:get_string("tutinfo_rawtext")
    end
    local width = meta:get("tutinfo_width") or "8"
    local height = meta:get("tutinfo_height") or"4.5"
    local btnx = ( (tonumber(width) or 7) / 2) - 1
    local btny = height - 1.5
    minetest.show_formspec(player:get_player_name(),
                           "informational",
                           "formspec_version[3]"..
                           "size["..width..","..height.."]"..
                           "hypertext[0.5,0.75;"..
                           width - 1 ..","..(height-2.5)..";introtext;"..
                           itext.."]"..
                           "button_exit["..btnx..","..btny..";2,1;X;- X -]")
end

ncrafting.register_switch(
    "tutorial_exile:info_node", {
        description = "An informational node",
        drawtype = "normal",
        tiles={
            "tech_woven.png",
            "tech_woven.png",
            "tut_info_box.png",
            "tut_info_box.png",
            "tut_info_box.png",
            "tut_info_box.png",
        },
        groups = { not_in_creative_inventory = 1 },
        _switch_sound = "",
        _on_use_node = function(player, _, pointed_thing)
            local pos = pointed_thing.under
            display_info(pos, player)
        end,
        on_rightclick = function(pos, _, puncher)
            if not minetest.is_player(puncher) then return end
            display_info(pos, puncher)
        end,
        on_punch = function(pos, _, puncher)
            if not minetest.is_player(puncher) then return end
            display_info(pos, puncher)
        end,
})

if minetest.is_creative_enabled() then
    minetest.override_item("tutorial_exile:info_node",
                           {
                               groups = { crumbly = 1, cracky = 3 },
    })
end

--- Exit button

local function do_exit(exiting, _, player)
    if exiting then
        tutorial.exit(player)
    end
end

local function exit_prompt(player)
    minimal.yes_or_no(player:get_player_name(),
                      S("Exit the tutorial?"),
                      do_exit)
end

ncrafting.register_switch(
    "tutorial_exile:exit_button", {
        description = "Exit",
        drawtype = "normal",
        tiles={
            "tut_exit.png",
        },
        groups = { not_in_creative_inventory = 1 },
        _switch_sound = "",
        _on_use_node = function(player, _, _)
            exit_prompt(player)
        end,
        on_rightclick = function(pos, _, puncher)
            if not minetest.is_player(puncher) then return end
            exit_prompt(puncher)
        end,
        on_punch = function(pos, _, puncher)
            if not minetest.is_player(puncher) then return end
            exit_prompt(puncher)
        end,
})

if minetest.is_creative_enabled() then
    minetest.override_item("tutorial_exile:exit_button",
                           {
                               groups = { crumbly = 1, cracky = 3 },
    })
end

core.register_node("tutorial_exile:exit_transporter", {
    description = S("Glowing Transporter Pad"),
    tiles = {"artifacts_antiquorium.png^[colorize:#B939:]"},
    light_source = 6,
    drawtype = "nodebox",
    paramtype = "light",
    node_box = {
        type = "fixed",
        fixed = {
            {-0.5, 0, -0.5, -0.125, 0.0625, -0.125}, -- NodeBox1
            {0.125, 0, -0.5, 0.5, 0.0625, -0.125}, -- NodeBox2
            {0.125, 0, 0.125, 0.5, 0.0625, 0.5}, -- NodeBox3
            {-0.5, 0, 0.125, -0.125, 0.0625, 0.5}, -- NodeBox4
            {-0.375, -0.125, -0.375, 0.375, 0.0, 0.375}, -- NodeBox5
            {-0.4375, -0.3125, -0.4375, 0.4375, -0.125, 0.4375}, -- NodeBox6
            {-0.5, -0.5, -0.5, 0.5, -0.3125, 0.5}, -- NodeBox7
            {-0.125, 0, -0.125, 0.125, 0.0625, 0.125}, -- NodeBox9
        }
    },
    groups = { cracky = 3, not_in_creative_inventory = 1 },
    sounds = nodes_nature.node_sound_glass_defaults(),
})
