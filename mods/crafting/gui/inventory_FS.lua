local S = minetest.get_translator("crafting")
-- Crafting formspec in inventory formspec -------------------------------------
--------------------------------------------------------------------------------

-- Register help formspec as inv tab
if not minetest.global_exists("sfinv") then error("Sfinv is missing?") end

-- returns a formspec to show a single crafting option
-- `pos`: string of the form "<X>,<Y>"
-- `img`: image (file name) that show a possible place for crafting
-- `hand_item`: hand item of the player to show
-- `tool_hand_png`: hand tool available for crafting at the place
-- `tool_2_png`: a second tool available for crafting at the place - optional
local function tip_fs(pos, img_no, hand_item, tool_hand_png, tool_2_png)
    local fs = {"container[".. pos .. "]"}
    fs[#fs + 1] = "image[0,0;3.1,2.4;crafting_help_" .. img_no .. ".png]"
    fs[#fs + 1] = "item_image[1.35,0.85;1.1,1.1;" .. hand_item .. "]"
    fs[#fs + 1] = "image[2.25,1.55;0.8,0.8;not_selected.png]"
    fs[#fs + 1] = "image[2.25,1.55;0.8,0.8;" .. tool_hand_png .. "]"
    if type(tool_2_png) == "string" then
        fs[#fs + 1] = "image[2.25,0.5;0.8,0.8;not_selected.png]"
        fs[#fs + 1] = "image[2.25,0.5;0.8,0.8;" .. tool_2_png .. "]"
        fs[#fs + 1] = "label[2.55,1.425;+]"
    end
    fs[#fs + 1] = "label[1.4,1.6;v]"
    fs[#fs + 1] = "container_end[]"
    return table.concat(fs, "")
end

sfinv.register_page(
    "crafting:help", {
        title = S("Crafting?"),
        get = function(self, player, context)
            -- get name and image of the player's hand item
            local item_name = "player_api:hand"
            if core.is_player(player) then
                local inv = player:get_inventory()
                local stack_1 = inv:get_stack("main", 1)
                local name = stack_1:get_name()
                -- make sure it is a hand item
                if name:find("player_api:hand", 1, true) then
                    item_name = name
                end
            end

            local fs = {"container[0.8,0.8]"}

            local tool1 = "tech_bare_hands.png"
            local tool2 = "tech_flat_clear_surface.png"
            local tool3 = "crafting_digging_stick.png"
            local tool4 = "crafting_mortar_pestle.png"

            fs[#fs + 1] = tip_fs("0,0",    "01", item_name, tool1)
            fs[#fs + 1] = tip_fs("3.35,0", "03", item_name, tool2)
            fs[#fs + 1] = tip_fs("6.7,0",  "05", item_name, tool2, tool3)

            fs[#fs + 1] = "container[0,2.7]"
            fs[#fs + 1] = tip_fs("0,0",    "02", item_name, tool1)
            fs[#fs + 1] = tip_fs("3.35,0", "04", item_name, tool2)
            fs[#fs + 1] = tip_fs("6.7,0",  "06", item_name, tool2, tool4)
            fs[#fs + 1] = "container_end[]"

            fs[#fs + 1] = "container[0,2.8]"
            fs[#fs + 1] = "image[0,2.6;9.8,1.6;crafting_help_progress.png]"
            fs[#fs + 1] = "item_image[0.50,3.4;0.8,0.8;tech:grass_fibre]"
            fs[#fs + 1] = "image[1.7,3.5;0.6,0.6;nodes_nature_tikusati.png^[hsl:0:30:-5]"
            fs[#fs + 1] = "image[1.95,3.3;0.7,0.7;nodes_nature_seeds.png]"
            fs[#fs + 1] = "item_image[3.80,3.25;0.8,0.8;inferno:fire_sticks]"
            fs[#fs + 1] = "item_image[5.15,3.4;0.7,0.7;tech:woven_blanket]"
            fs[#fs + 1] = "item_image[5.1,2.6;1.2,1.2;tech:food_bowl_clay_unfired]"
            fs[#fs + 1] = "item_image[7.1,3.5;0.6,0.6;stairs:stair_inner_silt]"
            fs[#fs + 1] = "item_image[7.3,3;0.6,0.6;stairs:slab_compost_undecomposed]"
            fs[#fs + 1] = "item_image[8.45,3.5;0.6,0.6;tech:mashed_anperla]"
            fs[#fs + 1] = "item_image[8.9,3.2;0.6,0.6;tech:vegetable_oil]"
            fs[#fs + 1] = "item_image[8.55,2.8;0.7,0.7;tech:paint_lime_white]"
            fs[#fs + 1] = "container_end[]"

            fs[#fs + 1] = "container_end[]"

            local content = table.concat(fs,"")
            return sfinv.make_formspec_for_exile(player, context,
                                                 content, false)
        end
})

-- disable sfinv:crafting without removing it, it's kept for compatibility with 3rd-party mods
-- and so we don't have to change the home page here
-- (we explicitly set the default page to clothing:clothing
-- in mods/player_api/init.lua after that page's per-player stuff is initialized).
sfinv.override_page("sfinv:crafting", {is_in_nav=function(...) return false end})
