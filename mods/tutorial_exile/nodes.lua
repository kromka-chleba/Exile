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



minetest.register_node(
    "tutorial_exile:wet_silt_grass", {
        description = "Wet Woodland Soil",
        tiles = {"nodes_nature_woodland_soil.png^nodes_nature_mud.png",
                 "nodes_nature_silt.png^nodes_nature_mud.png",
                 "nodes_nature_silt.png^"..
                     "nodes_nature_woodland_soil_side.png^"..
                     "nodes_nature_mud.png"
        },
        sounds = { footstep = {name = "nodes_nature_mud", gain = 0.4},
                   dug = {name = "nodes_nature_mud", gain = 0.4} },
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

local info = { -- #TODO: set up locales, template.txt etc
    ["dig_key"] = "^  "..S("Press the dig button to pick up or strike things."),
    ["place_key"] = "v  "..S("Press the place button to put things down."),
    ["use_key"] = "◊  "..S("Press the use button to activate items and nodes."..
                           "@n @n This is E by default on PC, AUX1 or sprint on mobile."),
    ["zoom_key"] = S("Press the zoom key to see the name of what "..
                     "you're looking at. @n This is Z by default on PC, "..
                     "and the binoculars or magnifying lens on mobile"),
    ["crawl"] = S("Double-tap sneak to crouch and get through small spaces.@n"..
                  "@nIf server lag makes this hard, you can use the"..
                  " /crouch command, or install exile_csm, the "..
                  "client-side mod to handle controls locally"),
    ["movement"] = S("Loss of energy affects move and jump rate"),
    ["torch"] = S("Drop a torch to see what's below")
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
