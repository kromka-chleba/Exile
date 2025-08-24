local S = minetest.get_translator("crafting")
-- Crafting formspec in inventory formspec -------------------------------------
--------------------------------------------------------------------------------

-- Register crafting formspec as inv tab
if not minetest.global_exists("sfinv") then error("Sfinv is missing?") end

-- I don't use overrider to have crafting page AFTER creative tbas
-- TODO better way to deal with tab order to implement
sfinv.register_page(
    "crafting:crafting", {
        title = S("Crafting"),
        get = function(self, player, context)
            -- initiates FS_cache[player_name] if non existant
            local cache = crafting.get_FS_cache(player, true)

            -- flag formspec as open if we changed tab in sfinv
            if context.open_inv then
                cache = crafting.open_formspec(player, "", cache)
            end

            -- last parameter is to indicate if inv fs is open for sure
            local formspec = crafting.make_crafting_formspec(player, cache)
            return sfinv.make_formspec_for_exile(player, context,
                                                 formspec, false)
        end,
        on_player_receive_fields = function(self, player, context, fields)
            -- if something changed, redraw the page
            local cache = crafting.process_receive_fields(player, "", fields)
            if cache then
                sfinv.set_player_inventory_formspec(player, context)
            end
            return true -- stop checking other events
        end,
        -- selecting the tab from an other tab or seting to crafting tab
        on_enter = function(self, player, context)
            -- WARNING: is called even if sfinv is closed, this is why I don't update the cache as "open" here
            -- reset station if needed (for next sfinv opening)
            crafting.set_station(player, nil)
            -- it is called before `get` function so formspec will be generated AFTER on_enter call
        end,
        -- triggered when leaving tab or by calling sfinv.set_page
        -- WARNING: be careful to not call sfinv.set_page here or you will get an infinite loop...
        on_leave = function(self, player, context)
            -- gives back input panel items and update player's cache
            crafting.close_crafting_formspec(player)
        end
})

-- Register help formspec as inv tab
sfinv.register_page(
    "crafting:help", {
        title = " ? ",
        get = function(self, player, context)
            local fs = {}
            fs[#fs + 1] = 'label[0.9,1.0;'.. S("Use a free hand at a suitable place (v).") .. ']'
            fs[#fs + 1] = 'image[0.8,2.0;4.8,3.5;crafting_help_surface_good_01.png]'
            fs[#fs + 1] = 'image[0.8,5.7;4.8,3.5;crafting_help_surface_good_02.png]'
            fs[#fs + 1] = 'image[5.8,2.0;4.8,3.5;crafting_help_surface_bad_01.png]'
            fs[#fs + 1] = 'image[5.8,5.7;4.8,3.5;crafting_help_surface_bad_02.png]'
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
