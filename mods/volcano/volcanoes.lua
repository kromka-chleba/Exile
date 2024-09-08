-- NOTE: This code contains some hacks to work around a number of bugs
--   in mapgen v7 and in Minetest's core mapgen code.
-- The issue URLs for those bugs are included in comments wherever
--   those hacks are used, if the issues get resolved
--   then the associated hacks should be removed.
-- https://github.com/minetest/minetest/issues/7878
-- https://github.com/minetest/minetest/issues/7864

local modpath = minetest.get_modpath(minetest.get_current_modname())

local ms = mapchunk_shepherd

ms.tag.register("volcano")

local volcano = volcano or {}

--
local water_level = tonumber(minetest.get_mapgen_setting("water_level"))
local mapgen_seed = tonumber(minetest.get_mapgen_setting("seed"))

--volcano size
local max_height = 500
local min_height = 300
local depth_root = -2000

--volcano spacing
local region_mapblocks = 32 --ie 16x80 = 1280 between
local mapgen_chunksize = tonumber(minetest.get_mapgen_setting("chunksize"))
local volcano_region_size = region_mapblocks * mapgen_chunksize * 16

--type probabilities
local p_active = 0.15
local p_dormant = 0.3
local p_extinct = 0.15
local state_dormant = 1 - p_active
local state_extinct = 1 - p_active - p_dormant
local state_none = 1 - p_active - p_dormant - p_extinct

if p_active + p_dormant + p_extinct > 1.0 then
    minetest.log("error", "[volcano] probabilities of various volcano types "..
                 "adds up to more than 1")
end

--shape
local depth_maxwidth = -30 -- point of maximum width
local slope_max = 2 --i.e. 2*300 = 600 radius
local radius_lining = 5 -- cf vent radius
local radius_cone_max =
    (max_height - depth_maxwidth) * slope_max + radius_lining + 20
local slope_min = 1

local caldera_min = 4 -- minimum radius of caldera
local caldera_max = 32 -- maximum radius of caldera

local chamber_radius_multiplier = 0.5

local depth_base = -50 -- point where the mountain root starts expanding

local radius_vent = 8 -- approximate minimum radius of vent - noise adds a lot to this

local depth_maxwidth_dist = depth_maxwidth-depth_base

--nodes

local c_ocean_sed =
    minetest.get_content_id("nodes_nature:gravel_wet_salty") --TODO: black sand

local c_ash = minetest.get_content_id("nodes_nature:volcanic_ash")
local c_sand = minetest.get_content_id("nodes_nature:sand") --TODO: black sand?
local c_gravel = minetest.get_content_id("nodes_nature:gravel")
local c_soil = minetest.get_content_id("nodes_nature:highland_soil")
--#TODO: maybe have a unique soil for volcano?

local c_moss = minetest.get_content_id("nodes_nature:moss")

local c_lava =  minetest.get_content_id("nodes_nature:lava_source")
local c_basalt = minetest.get_content_id("nodes_nature:basalt")
local c_scoria = minetest.get_content_id("nodes_nature:scoria")

local c_boulder_basalt = minetest.get_content_id("nodes_nature:basalt_boulder")
local c_boulder_scoria = minetest.get_content_id("nodes_nature:scoria_boulder")

local c_cobble_basalt = {}
c_cobble_basalt[1] = minetest.get_content_id("nodes_nature:basalt_cobble1")
c_cobble_basalt[2] = minetest.get_content_id("nodes_nature:basalt_cobble2")
c_cobble_basalt[3] = minetest.get_content_id("nodes_nature:basalt_cobble3")

local c_cobble_scoria = {}
c_cobble_scoria[1] = minetest.get_content_id("nodes_nature:scoria_cobble1")
c_cobble_scoria[2] = minetest.get_content_id("nodes_nature:scoria_cobble2")
c_cobble_scoria[3] = minetest.get_content_id("nodes_nature:scoria_cobble3")

local c_air = minetest.get_content_id("air")

local c_cone_1 = c_basalt
local c_cone_2 = c_scoria
------------------------------------------------------------------------
-- offset for alignment
local get_corner = function(pos)
    return {
        x = math.floor((pos.x+32) / volcano_region_size)
            * volcano_region_size - 32,
        z = math.floor((pos.z+32) / volcano_region_size)
            * volcano_region_size - 32}
end

------------------------------------------------------------------------
local scatter_2d = function(min_xz, gridscale, border_width)
    local bordered_scale = gridscale - 2 * border_width
    local point = {}
    point.x = math.random() * bordered_scale + min_xz.x + border_width
    point.y = 0
    point.z = math.random() * bordered_scale + min_xz.z + border_width
    return point
end

-------------------------------------------------------------------
--location and type
local get_volcano = function(pos)

    local corner_xz = get_corner(pos)
    local next_seed = math.random(1, 1000000000)
    math.randomseed(corner_xz.x + corner_xz.z * 2 ^ 8 + mapgen_seed)

    local state = math.random()
    if state < state_none then
        return nil
    end

    local location = scatter_2d(corner_xz, volcano_region_size, radius_cone_max)
    local depth_peak = math.random(min_height, max_height)
    local depth_lava

    if state < state_extinct then
        depth_lava = - math.random(1, math.abs(depth_root))
        -- extinct, put the lava somewhere deep.
    elseif state < state_dormant then
        depth_lava = depth_peak - math.random(5, 50) -- dormant
    else
        depth_lava = depth_peak - math.random(1, 25)
        -- active, put the lava near the top
    end
    local slope = math.random() * (slope_max - slope_min) + slope_min
    local caldera = math.random() * (caldera_max - caldera_min) + caldera_min

    math.randomseed(next_seed)
    return {location = location, depth_peak = depth_peak,
            depth_lava = depth_lava, slope = slope, state = state,
            caldera = caldera}
end

function volcano.nearby(pos)
    local corner_xz = get_corner(pos)
    math.randomseed(corner_xz.x + corner_xz.z * 2 ^ 8 + mapgen_seed)

    local state = math.random()
    math.randomseed(minetest.get_gametime()) -- fix randomness
    if state < state_none then
        return false
    end
    return true
end

function volcano.estimate_ground_level(pos)
    local volc = get_volcano(pos)
    if not volc then return end
    if volc.state < state_none then
        return
    end
    math.randomseed(minetest.get_gametime()) -- fix randomness
    local dist2peak = pos:distance(volc.location)
    return volc.depth_peak - dist2peak / volc.slope + 10
end

-----------------------------------------------------------------------------
local perlin_params = {
    offset = 0,
    scale = 1,
    spread = {x=32, y=32, z=32},
    seed = -40681,
    octaves = 3,
    persist = 0.7
}

local perlin_caves = {
    offset = 0,
    scale = 1,
    spread = {x=96, y=16, z=96},
    seed = -9681,
    octaves = 3,
    persist = 0.3
}

local nvals_perlin_buffer = {}
local nobj_perlin = nil

local nvals_perlin_caves_buffer = {}
local nobj_perlin_caves = nil

local data = {}
local p2data = {}



-----------------------------------------------------------
minetest.register_on_generated(function(vm, minp, maxp, seed)
	--outside range
	if minp.y > max_height or maxp.y < depth_root then
		return
	end

        local volcano = get_volcano(minp)

        if volcano == nil then
            return -- no volcano in this map region
        end

        local depth_peak = volcano.depth_peak
        local base_radius =
            (depth_peak - depth_maxwidth) * volcano.slope + radius_lining
        local chamber_radius =
            (base_radius / volcano.slope) * chamber_radius_multiplier

        -- early out if the volcano is too far away to matter
        -- The plus 20 is because the noise being added will generally be in
        --  the 0-20 range, see the "distance" calculation below
        if volcano.location.x - base_radius - 20 > maxp.x
            or volcano.location.x + base_radius + 20 < minp.x
            or volcano.location.z - base_radius - 20 > maxp.z
            or volcano.location.z + base_radius + 20 < minp.z
        then
            return
        end

	local emin, emax = vm:get_emerged_area()
	local area = VoxelArea:new{MinEdge=emin, MaxEdge=emax}
	vm:get_data(data)
	vm:get_param2_data(p2data)

    -- Add the "volcano" label to volcano chunks
    local hash = ms.mapchunk_hash(emin)
    local volcano_watchdog = ms.mapgen_watchdog.new(hash)
    volcano_watchdog:mark_for_addition("volcano")
    volcano_watchdog:save_gen_notify()

        local sidelen = mapgen_chunksize * 16 --length of a mapblock
        local chunk_lengths = {x = sidelen,
                               y = sidelen,
                               z = sidelen} --table of chunk edges

        nobj_perlin = nobj_perlin
            or minetest.get_perlin_map(perlin_params, chunk_lengths)
        local nvals_perlin = nobj_perlin:get_3d_map_flat(minp,
                                                         nvals_perlin_buffer)

        nobj_perlin_caves = nobj_perlin_caves
            or minetest.get_perlin_map(perlin_caves, chunk_lengths)
        local nvals_perlin_caves =
            nobj_perlin_caves:get_3d_map_flat(minp,
                                              nvals_perlin_caves_buffer)


        local noise_area = VoxelArea:new{MinEdge=minp, MaxEdge=maxp}
        local noise_iterator = noise_area:iterp(minp, maxp)

        local x_coord = volcano.location.x
        local z_coord = volcano.location.z
        local depth_lava = volcano.depth_lava
        local caldera = volcano.caldera
        local state = volcano.state


        -------------------------------------------------
        for vi, x, y, z in area:iterp_xyz(minp, maxp) do
            local vi3d = noise_iterator()

            local nvals = nvals_perlin[vi3d]
            local nvals_caves = nvals_perlin_caves[vi3d]

            local distance_perturbation = (nvals+1)*10
            local distance = vector.distance({x=x, y=y, z=z},
                {x=x_coord, y=y, z=z_coord}) - distance_perturbation


            -- Determine what materials to use at this y level
            local c_top
            local c_filler
            local c_dust

            if state < state_dormant then
                if math.random()<0.33 then
                    c_dust = c_moss
                end
                if y < water_level + 2 then
                    c_top = c_ocean_sed
                    c_filler = c_ocean_sed
                elseif math.random()>0.95 then
                    c_top = c_ash
                    c_filler =  c_gravel
                elseif math.random()>0.75 then
                    c_top = c_sand
                    c_filler = c_gravel
                else
                    c_top = c_soil
                    c_filler =  c_gravel
                end

            elseif math.random()>0.90 then
                c_top = c_sand
                c_filler =  c_gravel
            elseif math.random()>0.80 then
                c_top = c_ash
                c_filler = c_gravel
            else
                c_top = c_scoria
                c_filler =  c_basalt
            end

            local pipestuff
            local liningstuff
            if y < depth_lava + math.random() * 1.1 then
                pipestuff = c_lava
                if math.random()>0.5 then
                    liningstuff = c_cone_1
                else
                    liningstuff = c_cone_2
                end
            else
                if state < state_dormant then
                    if math.random()>0.5 then
                        pipestuff = c_cone_1
                    else
                        pipestuff = c_cone_2
                    end
                    if math.random()>0.5 then
                        liningstuff = c_cone_1
                    else
                        liningstuff = c_cone_2
                    end
                else
                    pipestuff = c_air
                    if math.random()>0.5 then
                        liningstuff = c_cone_1
                    else
                        liningstuff = c_cone_2
                    end
                end
            end

            -- Actually create the volcano
            if y < depth_base then

                if y < depth_root + chamber_radius then -- Magma chamber lower half
                    local lower_half =
                        ((y - depth_root) / chamber_radius) * chamber_radius

                    if distance < lower_half + radius_vent then
                        data[vi] = c_lava
                        -- Put lava in the magma chamber even for extinct
                        -- volcanoes, if someone really wants to dig for it
                        -- it's down there.
                    elseif distance < lower_half + radius_lining
                        and data[vi] ~= c_air
                        and data[vi] ~= c_lava then
                        -- leave holes into caves and into existing lava
                        data[vi] = liningstuff
                    end
                elseif y < depth_root + chamber_radius * 2 then
                    -- Magma chamber upper half
                    local upper_half =
                        (1 - (y - depth_root - chamber_radius)
                         / chamber_radius) * chamber_radius
                    if distance < upper_half + radius_vent then
                        data[vi] = c_lava
                    elseif distance < upper_half + radius_lining
                        and data[vi] ~= c_air
                        and data[vi] ~= c_lava then
                        -- leave holes into caves and into existing lava
                        data[vi] = liningstuff
                    end
                else -- pipe
                    if distance < radius_vent then
                        data[vi] = pipestuff
                    elseif distance < radius_lining
                        and data[vi] ~= c_air
                        and data[vi] ~= c_lava then
                        -- leave holes into caves and into existing lava
                        data[vi] = liningstuff
                    end
                end

            elseif y < depth_maxwidth then -- root
                if distance < radius_vent then
                    data[vi] = pipestuff
                elseif distance < radius_lining then
                    data[vi] = liningstuff
                elseif distance < radius_lining + (
                    (y - depth_base)/depth_maxwidth_dist) * base_radius then

                    if math.random()>0.5 then
                        data[vi] = c_cone_1
                    else
                        data[vi] = c_cone_2
                    end
                end

            elseif y < depth_peak + 5 then -- cone
                local current_elevation = y - depth_maxwidth
                local peak_elevation = depth_peak - depth_maxwidth

                if current_elevation > peak_elevation - caldera
                    and distance < current_elevation
                    - peak_elevation + caldera then

                    data[vi] = c_air -- caldera
                elseif distance < radius_vent then
                    data[vi] = pipestuff
                elseif distance < radius_lining then
                    data[vi] = liningstuff
                elseif ( distance <  current_elevation
                         * -volcano.slope + base_radius )then
                    if nvals_caves > 0 and nvals_caves < 0.1
                        and nvals > 0 and nvals < 0.15 then
                        if state < state_dormant then
                            pipestuff = c_air
                        end
                        data[vi] = pipestuff
                    else
                        if math.random()>0.5 then
                            data[vi] = c_cone_1
                        else
                            data[vi] = c_cone_2
                        end
                    end

                    if data[vi + area.ystride] == c_air and c_dust ~= nil then
                        local die = math.random()
                        if c_dust ~= c_boulder then -- #FIXME: No such thing?
                            if die > 0.98 then
                                c_dust = c_boulder_basalt
                            elseif die > 0.95 then
                                c_dust = c_cobble_basalt[math.random(1,3)]
                                p2data[vi + area.ystride] = math.random(0,3)
                            elseif die > 0.90 then
                                c_dust = c_boulder_scoria
                            elseif die > 0.85 then
                                c_dust = c_cobble_scoria[math.random(1,3)]
                                p2data[vi + area.ystride] = math.random(0,3)
                            end
                        end
                        data[vi + area.ystride] = c_dust
                    end

                elseif c_top ~= nil
                    and c_filler ~= nil
                    and ( distance < current_elevation * -volcano.slope
                          + base_radius + nvals_perlin[vi3d] +1.5 ) then
                    data[vi] = c_top

                    if data[vi - area.ystride] == c_top then
                        data[vi - area.ystride] = c_filler
                    end

                    if data[vi + area.ystride] == c_air then
                        local die = math.random()

                        if die > 0.99 then
                            data[vi + area.ystride] = c_boulder_basalt
                        elseif        die > 0.98 then
                            data[vi + area.ystride] =
                                c_cobble_basalt[math.random(1,3)]
                            p2data[vi + area.ystride] = math.random(0,3)
                        elseif die > 0.93 then
                            data[vi + area.ystride] = c_boulder_scoria
                        elseif        die > 0.92 then
                            data[vi + area.ystride] =
                                c_cobble_scoria[math.random(1,3)]
                            p2data[vi + area.ystride] = math.random(0,3)
                        elseif die > 0.90 then
                            data[vi + area.ystride] = c_moss
                        elseif c_dust ~= nil then
                            data[vi + area.ystride] = c_dust
                        end
                    end
                end
            end
        end

	--send data back to voxelmanip
	vm:set_data(data)
	vm:set_param2_data(p2data)
	--calc lighting
	vm:calc_lighting()
	vm:update_liquids()
end)
