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
            local formspec = crafting.make_crafting_formspec(player)
            return sfinv.make_formspec_for_exile(player, context,
                                                 formspec, false)
        end,
        on_player_receive_fields = function(self, player,
                                            context, fields)
            -- if something changed, redraw the page
            if crafting.process_receive_fields(player, "", fields) then
                sfinv.set_player_inventory_formspec(player, context)
            end
        end,
        -- selecting the tab from an other tab
        on_enter = function(self, player, context)
            print ("--------------------------]ENTER[-------------------")
            -- get or generate cache
            local cache = crafting.get_FS_cache(player, true)
            cache.updated = true -- no need for refresh button
            -- sfinv refresh
            sfinv.set_player_inventory_formspec(player)


            --set_cache(player:get_player_name(),player:get_inventory())
        end,
        -- triggered when leaving tab or if we change page in sfinv
        on_leave = function(self, player, context)
            print ("--------------------------]LEAVE[-------------------")
            -- gives back input panle items and deletes cache
            crafting.close_crafting_formspec(player)
            --cache = "closed" -- old version
            -- We may change that and not delete but trigger dfferent things if on leave ?
        end
})
