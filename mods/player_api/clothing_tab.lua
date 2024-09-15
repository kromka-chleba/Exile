-- Internationalization
local S = minetest.get_translator("player_api")
local FS = function(...)
    return minetest.formspec_escape(S(...))
end

------------------------------------------------------------
-- Inventory page to create "clothing" tab formspec
local clothing_page = {
    title = S("Clothing"),
    get = function(self, player, context)
        local meta = player:get_meta()
        local cur_tmin = climate.get_temp_string(meta:get_int("clothing_temp_min"), meta)
        local cur_tmax = climate.get_temp_string(meta:get_int("clothing_temp_max"), meta)
        local basetex = minetest.formspec_escape(
            player_api.get_current_texture(player) )

        local formspec = "container[0,0]" ..
            "label[4,1;" .. FS("Min Temperature Tolerance: @1", cur_tmin) .. " ]"..
            "label[4,1.5;" .. FS("Max Temperature Tolerance: @1", cur_tmax) .. " ]"..         
              
            --model overview
            -- #TODO do not change rotation angle when changing clothes, if possible, maybe saving the current angle in context/cache like in crafting tab
            "model[5.2,2.45;2.6,3.9;character;character.b3d;"..basetex..
            ";-20,160;;true;;]" ..
            
            --2) inventories
            -- #TODO add images or tooltips to indicate what goes where
            "list[current_player;hat;4,2;1,1;]" ..
            "list[current_player;shirt;4,3.25;1,1;]" ..
            "list[current_player;pants;4,4.5;1,1;]" ..
            "list[current_player;shoes;4,5.75;1,1;]" ..
            "list[current_player;cape;8,3.25;1,1;]" ..
            "list[current_player;blanket;8,4.5;1,1;]" ..
            --player inventory display : currently done in sfinv/api.lua   
            --"list[current_player;main;0.35,7.3;8,1;]"..
            --"list[current_player;main;0.35,8.55;8,3;8]" ..
            "label[0.35,10.2;Tip : use \"shift\" key to switch clothes]" ..
            
            -- enable equip with "shift" key.
            "listring[current_player;main]"..
            "listring[current_player;temp_slot]"..
                
            "container_end[]"
            -- call a function making a size[10.5,10.9] formspec with that content and adding tabs if needed
        return sfinv.make_formspec(player, context,
                                   formspec, true)
    end
}

sfinv.register_page("clothing:clothing", clothing_page)
