local S = minetest.get_translator("crafting")
-- Crafting formspec in inventory formspec -------------------------------------
--------------------------------------------------------------------------------

-- Register crafting formspec as inv tab
if not minetest.global_exists("sfinv") then error("Sfinv is missing?") end

local homepage = sfinv.get_homepage_name() -- get name of homepage
sfinv.remove_page(homepage)

sfinv.register_page(
    homepage, {
        title = S("Crafting"),
        get = function(self, player, context)
            local formspec = crafting.make_crafting_formspec(player,context)
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
            --local player_name = player:get_player_name()
            print ("--------------------------]ENTER[-------------------")
            --set_cache(player:get_player_name(),player:get_inventory())
        end,
        on_leave = function(self, player, context)
            --local player_name = player:get_player_name()
            --cache = "closed" -- #TODO not sure about that
            print ("--------------------------]LEAVE[-------------------")
        end,
        --  on_enter = function(self, player, context)
        --          local player_name = player:get_player_name()
        --          local cache= FS_cache[player_name]
        --          if cache and type(cache) == table then
        --              cache.c_recipes=nil
        --              cache.u_recipes=nil
        --          end
        --          sfinv.set_player_inventory_formspec(player,context)
        --  end
})
