local S = minetest.get_translator("crafting")
-- Crafting formspec in inventory formspec -------------------------------------
--------------------------------------------------------------------------------

-- Register help formspec as inv tab
if not minetest.global_exists("sfinv") then error("Sfinv is missing?") end

sfinv.register_page(
    "crafting:help", {
        title = S("Crafting?"),
        get = function(self, player, context)
            local fs = {'container[0.8,0.8]'}
            -- NOTE: The extra 'new line' is to indicate to translators and
            --       coders: There is/needs to be space for 3 lines of text.
            local text = S("Use an empty hand anywhere for simple manual "
                    .. "tasks,@nor on a flat, clear surface for more "
                    .. "options.@nOr use placed tools or crafting stations.")
            fs[#fs + 1] = 'label[0,0;'.. text .. ']'

            -- leave space for a 4th line of translations!
            fs[#fs + 1] = 'container[0,1.8]'
            fs[#fs + 1] = 'image[0,0;3.1,2.4;crafting_help_01.png]'
            fs[#fs + 1] = 'image[2.15,1.45;0.9,0.9;not_selected.png]'
            fs[#fs + 1] = 'image[2.15,1.45;0.9,0.9;tech_bare_hands.png]'

            fs[#fs + 1] = 'image[0,2.65;3.1,2.4;crafting_help_02.png]'
            fs[#fs + 1] = 'image[2.15,4.1;0.9,0.9;not_selected.png]'
            fs[#fs + 1] = 'image[2.15,4.1;0.9,0.9;tech_bare_hands.png]'

            fs[#fs + 1] = 'image[3.35,0;3.1,2.4;crafting_help_03.png]'
            fs[#fs + 1] = 'image[5.5,1.45;0.9,0.9;not_selected.png]'
            fs[#fs + 1] = 'image[5.5,1.45;0.9,0.9;tech_flat_clear_surface.png]'

            fs[#fs + 1] = 'image[3.35,2.65;3.1,2.4;crafting_help_04.png]'
            fs[#fs + 1] = 'image[5.5,4.1;0.9,0.9;not_selected.png]'
            fs[#fs + 1] = 'image[5.5,4.1;0.9,0.9;tech_flat_clear_surface.png]'

            fs[#fs + 1] = 'image[6.7,0;3.1,2.4;crafting_help_05.png]'
            fs[#fs + 1] = 'image[8.85,1.45;0.9,0.9;not_selected.png]'
            fs[#fs + 1] = 'image[8.85,1.45;0.9,0.9;crafting_digging_stick.png]'

            fs[#fs + 1] = 'image[6.7,2.65;3.1,2.4;crafting_help_06.png]'
            fs[#fs + 1] = 'image[8.85,4.1;0.9,0.9;not_selected.png]'
            fs[#fs + 1] = 'image[8.85,4.1;0.9,0.9;crafting_mortar_pestle.png]'
            fs[#fs + 1] = 'container_end[]'
            fs[#fs + 1] = 'container_end[]'

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
