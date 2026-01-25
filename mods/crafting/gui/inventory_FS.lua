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
            -- NOTE: The extra "new line" is to indicate to translators and
            --       coders: There is/needs to be space for 3 lines of text.
            local text = S("Use an empty hand anywhere for simple manual "
                    .. "tasks,@nor on a flat, clear surface for more "
                    .. "options.@nOr use placed tools or crafting stations.")
            fs[#fs + 1] = "label[0,0;".. text .. "]"

            -- leave space for a 4th line of translations!
            fs[#fs + 1] = "container[0,1.8]"

            local tool1 = "tech_bare_hands.png"
            local tool2 = "tech_flat_clear_surface.png"
            local tool3 = "crafting_digging_stick.png"
            local tool4 = "crafting_mortar_pestle.png"

            fs[#fs + 1] = tip_fs("0,0",       "01", item_name, tool1)
            fs[#fs + 1] = tip_fs("0,2.65",    "02", item_name, tool1)
            fs[#fs + 1] = tip_fs("3.35,0",    "03", item_name, tool2)
            fs[#fs + 1] = tip_fs("3.35,2.65", "04", item_name, tool2)
            fs[#fs + 1] = tip_fs("6.7,0",     "05", item_name, tool2, tool3)
            fs[#fs + 1] = tip_fs("6.7,2.65",  "06", item_name, tool2, tool4)

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
