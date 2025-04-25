-- This file contains quick blocks of code that can be enabled for debugging
--
--
exile = exile
exile.debug = exile.debug or {}

-- show the list of registered crafting types and matching recipes
exile.register_debug_fun("show_crafting_types",
    function()
        for name, type in pairs(crafting.get_type) do
            minetest.log('warning', "station: "..name..
                        "(recipes: "..#type.recipes..")")
    end
end)
