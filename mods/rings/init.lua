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

dofile(minetest.get_modpath("rings") .. "/noise.lua")
noise_handler = noise_handler

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

if deco.map_version ~= "v3" then -- Mt Meru can generate partially on old maps
    dofile(minetest.get_modpath("rings") .. "/meru.lua")
end

local c_ring_o = minetest.get_content_id("rings:antiquorium")
-- outer shell material
local c_ring_i = minetest.get_content_id("rings:moon_glass")
-- inner shell material -- TODO: replace this with a glowing material


--[[ allow tree trunks to "grow" through rings by not deleting them during ring creation --]]
-- c_node_list is an integer-keyed table for fast lookups during the x-y-z loop
-- register after mods are loaded so all tree node content ids are available

local c_node_list = {}
minetest.register_on_mods_loaded(function()
        -- get content ids for all tree types
        for _,treelist in pairs(nodes_nature.trees.list) do
            local tree = core.registered_nodes[treelist.tree]
            c_node_list[core.get_content_id(tree.name)] = true
            -- add leaves and fruits to nodes that can cut through rings
            if tree.tree_leaves then
                for _,leaf in ipairs(tree.tree_leaves) do
                    c_node_list[core.get_content_id(leaf)] = true
                end
            end
            if tree.tree_fruits then
                for _,fruit in ipairs(tree.tree_fruits) do
                    c_node_list[core.get_content_id(fruit)] = true
                end
            end
        end

        -- debug info.  uncomment here and set exile_debug to true to enable
        --exile.debug.log_to_world( "c_ring_o = " .. c_ring_o .. "\n" )
        --exile.debug.log_to_world( "c_ring_i = " .. c_ring_i .. "\n" )
        --exile.debug.log_to_world( "c_node_list = " .. dump(c_node_list) .. "\n\n" )
end)


--noise parameters
-- base terrain height
np_2d_base = {
    offset = 0,
    scale = 7,
    spread = {x = 80, y = 80, z = 80},
    seed = 0,
    octaves = 3,
    persist = 0.5,
    lacunarity = 3,
    -- flags = "noeased",
}
-- cracks in the shells of the great rings
np_3d_ring = {
    offset = 0,
    scale = 1,
    spread = {x = 8, y = 8, z = 8},
    seed = 0,
    octaves = 1,
    persist = 1,
    lacunarity = 1.0,
    -- flags = "absvalue",
}

local chunk_size = {x = 80, y = 80, z = 80}

local nobj_2d_b = noise_handler.get_noise_object(np_2d_base, chunk_size)
local nobj_3d_r = noise_handler.get_noise_object(np_3d_ring, chunk_size)

local data = {}

local function ring_ongen(minp, maxp, blockseed)
    -- check block elevation (not too high or low)
    if maxp.y < 40 or minp.y > 80 then
        return
    end

    -- 1-in-70 chance of generating a ring
    if math.floor(blockseed / 100) % 70 > 0 then
        return
    end

    -- get voxelmanip node data
    local vm, emin, emax = minetest.get_mapgen_object("voxelmanip")
    local area = VoxelArea:new({MinEdge=emin, MaxEdge=emax})
    vm:get_data(data)

    -- noise & randomness
    local nvals_2d_b = nobj_2d_b:get_2d_map_flat(minp)
    local nvals_3d_r = nobj_3d_r:get_3d_map_flat(minp)

    math.randomseed(blockseed)

    -- ring axis direction and centroid position
    -- axis vector is random inside a 1.0 x 0.5 x 1.0 box, centered on (0,0,0)
    -- centroid is horizontally centered in chunk, elevation based on 2d noise
    local rdir, rpos
    rdir = vector.new(math.random() - 0.5,
                      (math.random() - 0.5)/2, math.random() - 0.5)
    rpos = {}
    rpos.x = math.floor((minp.x + maxp.x) / 2)
    rpos.z = math.floor((minp.z + maxp.z) / 2)
    rpos.y = math.floor(nvals_2d_b[(rpos.z-minp.z) * 80 + (rpos.x-minp.x) + 1])

    -- debug info.  uncomment here and set exile_debug to true to enable
    --exile.debug.log_to_world( "\nblockseed = " .. blockseed .. "\n" )
    --exile.debug.log_to_world( "emin=" .. dump(emin) .. ")\n" )
    --exile.debug.log_to_world( "emax=" .. dump(emax) .. ")\n" )
    --exile.debug.log_to_world( "rpos=(" .. rpos.x .. ',' .. rpos.y .. ',' .. rpos.z .. ")\n" )
    --exile.debug.log_to_world( "rdir=(" .. rdir.x .. ',' .. rdir.y .. ',' .. rdir.z .. ")\n" )
    --exile.debug.log_to_world( "rdir_length=" .. vector.length(rdir) .. "\n" )

    -- shells are defined by node distance from the ring centroid
    -- use distance squared to avoid computationally expensive square root operations
    local dd_o_min = math.pow(30, 2) -- outer shell min distance squared
    local dd_i_min = math.pow(31, 2) -- inner shell min distance squared
    local dd_i_max = math.pow(34, 2) -- inner shell max distance squared
    local dd_o_max = math.pow(35, 2) -- outer shell max distance squared

    for z = minp.z, maxp.z do
        for y = minp.y, maxp.y do
            for x = minp.x, maxp.x do

                local vi = area:index(x, y, z)

                if not c_node_list[data[vi]] then -- not at a tree node

                    local dd_node = math.pow(rpos.x - x, 2)
                        + math.pow(rpos.z - z, 2)
                        + math.pow(rpos.y - y, 2)  -- node distance squared
                    local s_proj = math.abs((x-rpos.x)
                        * rdir.x + (y-rpos.y)
                        * rdir.y + (z-rpos.z) * rdir.z)
                    -- node dist projected on axis and scaled by axis length
                    local nv_3d_r = nvals_3d_r[(z - minp.z) * 80 * 80
                        + (y - minp.y) * 80 + (x - minp.x) + 1]
                    -- outer shell crack noise

                    if (dd_node > dd_i_min) and (dd_node < dd_i_max)
                        and (s_proj <= 2.0) then
                        data[vi] = c_ring_i  -- place inner shell
                    end

                    if (dd_node > dd_o_min) and (dd_node < dd_o_max)
                        and (s_proj <= 3.0) and (nv_3d_r < 0.3)
                        and (data[vi] ~= c_ring_i) then
                        data[vi] = c_ring_o  -- place outer shell
                    end

                end

            end
        end
    end

    vm:set_data(data)
    vm:calc_lighting()
    vm:write_to_map()
    minetest.fix_light(minp, maxp)
end
minetest.register_on_generated(ring_ongen)
