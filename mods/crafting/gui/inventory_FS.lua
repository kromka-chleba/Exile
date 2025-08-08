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
                cache.open = ""
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
