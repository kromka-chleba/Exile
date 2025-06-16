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
            -- last parameter is to indicate if inv fs is open for sure
            local formspec = crafting.make_crafting_formspec(player,
                                                            context.open_inv)
            return sfinv.make_formspec_for_exile(player, context,
                                                 formspec, false)
        end,
        on_player_receive_fields = function(self, player,
                                            context, fields)
            -- if something changed, redraw the page
            local cache = crafting.process_receive_fields(player, "", fields)
            if cache then
                sfinv.set_player_inventory_formspec(player, context)
            end
        end,
        -- selecting the tab from an other tab or seting to crafting tab
        on_enter = function(self, player, context)
            print ("--------------------------]ENTER[-------------------")
            -- WARNING: is called even if sfinv is closed, this is why I don't update the cache here

            -- it is called before `get` function so formspec will be generated AFTER on_enter call
        end,
        -- triggered when leaving tab or if we change page in sfinv
        on_leave = function(self, player, context)
            print ("--------------------------]LEAVE[-------------------")
            -- gives back input panle items
            crafting.close_crafting_formspec(player)
            --[[be careful to not update sfinv page here or you may get infinite loop.]]
            -- TODO We may change that and not delete but trigger dfferent things if on leave ?
        end
})
