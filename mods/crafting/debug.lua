-- This file contains quick blocks of code that can be enabled for debugging
--
--
exile = exile
exile.debug = exile.debug or {}

function exile.debug.crafting_stations(station)
    for _,recipes in pairs(crafting.recipes) do
        minetest.log('warning', "station: "..station..
                     "(recipes: "..#recipes..")")
    end
    if station then
        print (dump(crafting.recipes[station]))
    end
end
