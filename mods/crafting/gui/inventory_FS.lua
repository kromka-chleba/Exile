local S = minetest.get_translator("crafting")
-- Crafting formspec in inventory formspec -------------------------------------
--------------------------------------------------------------------------------

-- Register help formspec as inv tab
if not minetest.global_exists("sfinv") then error("Sfinv is missing?") end

sfinv.register_page(
    "crafting:help", {
        title = S("Crafting?"),
        get = function(self, player, context)
            local fs = {}
            -- NOTE: The extra 'new line' is to indicate to translators and
            --       coders: There is/needs to be space for 3 lines of text.
            local text = S("@nUse an empty hand on a flat, clear surface,"
                      .. "@nor use a placed tool or crafting station.")
            fs[#fs + 1] = 'label[0.8,0.8;'.. text .. ']'
            fs[#fs + 1] = 'image[0.8,2.3;3.1,2.4;crafting_help_surface_good_01.png]'
            fs[#fs + 1] = 'image[4.15,2.3;3.1,2.4;crafting_help_surface_good_03.png]'
            fs[#fs + 1] = 'image[7.5,2.3;3.1,2.4;crafting_help_surface_good_04.png]'
            fs[#fs + 1] = 'image[0.8,4.95;3.1,2.4;crafting_help_surface_good_02.png]'
            fs[#fs + 1] = 'image[4.15,4.95;3.1,2.4;crafting_help_surface_bad_01.png]'
            fs[#fs + 1] = 'image[7.5,4.95;3.1,2.4;crafting_help_surface_bad_02.png]'
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
