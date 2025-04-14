-- This file contains quick blocks of code that can be enabled for debugging
--
--
exile = exile
exile.debug = exile.debug or {}

function exile.debug.crafting_stations(station)
    local r_list = crafting.get_recipes_list()
    for _,recipes in pairs(r_list) do
        minetest.log('warning', "station: "..station..
                     "(recipes: "..#recipes..")")
    end
    if station then
        print (dump(r_list[station]))
    end
end
