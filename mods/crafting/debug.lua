-- This file contains quick blocks of code that can be enabled for debugging
--
--

-- show the list of registered crafting types and matching recipes
EXILE.register_debug_fun("show_crafting_types",
    function()
        for name, type in pairs(crafting.get_type) do
            minetest.log('warning', "station: "..name..
                        "(recipes: "..#type.recipes..")")
    end
end)
