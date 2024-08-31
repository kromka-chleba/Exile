--[[
Copyright (c) 2022 Skamiz

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
--]]

local c_alpha = minimal.compat_alpha

-- This is very risky bc. nothing indicates to artifacts, that their locale is used here
-- In case more translation strings are added, this mod should get it's own textdomain
local artifacts_S = minetest.get_translator("artifacts")

minetest.register_node("rings:antiquorium", {
	description = artifacts_S("Antiquorium"),
	tiles = {"artifacts_antiquorium.png"},
	stack_max = minimal.stack_max_bulky *4,
	sounds = nodes_nature.node_sound_glass_defaults(),
	paramtype = "light",
	groups = {cracky = 1, not_in_creative_inventory = 1},
	drop = "artifacts:antiquorium"
})

minetest.register_node("rings:moon_glass", {
	description = artifacts_S("Moon Glass"),
	drawtype = "glasslike",
	tiles = {"artifacts_moon_glass.png"},
	stack_max = minimal.stack_max_bulky *4,
	light_source = 5,
	paramtype = "light",
	sunlight_propagates  = true,
	use_texture_alpha = c_alpha.clip,
	sounds = nodes_nature.node_sound_glass_defaults(),
	groups = {cracky = 1, not_in_creative_inventory = 1},
	drop = "artifacts:moon_glass",
})
