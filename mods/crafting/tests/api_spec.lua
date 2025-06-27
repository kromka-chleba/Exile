package.path = '../../?.lua;' .. -- tests root
    '../?.lua;' .. -- mod root
    package.path

require("crafting/tests/dummy")
require("crafting/api")

local recipe1 = {
    type   = "test",
    output = "default:torch",
    items  = { "default:stick", "default:coal" },
    always_known = true,
}

local recipe2 = {
    type   = "test",
    output = "default:stone",
    items  = { "default:cobble" },
    always_known = true,
}

describe("Recipes and types", function()
            crafting.reset_craft_types()

             it("can register type", function()
                    assert.is_nil(crafting.get_recipes_by_type("test"))
                    crafting.register_type("test")
                    assert.is_not_nil(crafting.get_recipes_by_type("test"))
             end)

             it("can register type", function()
                    assert(not crafting.get_recipes_by_type("test")[1])
                    crafting.register_recipe(recipe1)
                    assert.is_not_nil(crafting.get_recipes_by_type("test")[1])
                    assert.equals(crafting.get_recipes_by_type("test")[1].output, recipe1.output)
             end)
end)


describe("Getting all outputs", function()
             crafting.reset_craft_types()
             crafting.register_type("test")

             -- Recipe 1
             crafting.register_recipe(recipe1)
             assert.equals(#crafting.get_recipes_by_type("test"), 1)
             assert.equals(crafting.get_recipes_by_type("test")[1].output, recipe1.output)

             -- Recipe 2
             crafting.register_recipe(recipe2)
             assert.equals(#crafting.get_recipes_by_type("test"), 2)
             assert.equals(crafting.get_recipes_by_type("test")[1].output, recipe1.output)
             assert.equals(crafting.get_recipes_by_type("test")[2].output, recipe2.output)

             it("get with no items", function()
                    local recipes = crafting.get_all("test", 1, {}, {})
                    assert.equals(2, #recipes)

                    assert.equals(recipe1, recipes[1].recipe)
                    assert.equals(recipe2, recipes[2].recipe)
                    assert.is_false(recipes[1].craftable)
                    assert.is_false(recipes[2].craftable)
             end)

             it("get with right for one", function()
                    local items_hash = {}
                    items_hash["default:cobble"] = 1

                    local recipes = crafting.get_all("test", 1, items_hash, {})
                    assert.equals(2, #recipes)

                    assert.equals(recipe1, recipes[1].recipe)
                    assert.equals(recipe2, recipes[2].recipe)
                    assert.is_false(recipes[1].craftable)
                    assert.is_true(recipes[2].craftable)
             end)
end)
