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
	minetest.log("error", "[volcano] probabilities of various volcano types adds up to more than 1")
end

--shape
local depth_maxwidth = -30 -- point of maximum width
local slope_max = 2 --i.e. 2*300 = 600 radius
local radius_lining = 5 -- cf vent radius
local radius_cone_max =  (max_height - depth_maxwidth) * slope_max + radius_lining + 20
local slope_min = 1

local caldera_min = 4 -- minimum radius of caldera
local caldera_max = 32 -- maximum radius of caldera

local chamber_radius_multiplier = 0.5

local depth_base = -50 -- point where the mountain root starts expanding

local radius_vent = 8 -- approximate minimum radius of vent - noise adds a lot to this

local depth_maxwidth_dist = depth_maxwidth-depth_base

------------------------------------------------------------------------
-- offset for alignment
local get_corner = function(pos)
   return {x = math.floor((pos.x+32) / volcano_region_size) * volcano_region_size - 32,
	   z = math.floor((pos.z+32) / volcano_region_size) * volcano_region_size - 32}
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
		depth_lava = - math.random(1, math.abs(depth_root)) -- extinct, put the lava somewhere deep.
	elseif state < state_dormant then
		depth_lava = depth_peak - math.random(5, 50) -- dormant
	else
		depth_lava = depth_peak - math.random(1, 25) -- active, put the lava near the top
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

----------------------------------------------------------------------------------------------
-- Debugging and sightseeing commands

minetest.register_privilege(
    "findvolcano",
    {description =
         "Allows players to use a console command to find volcanoes",
     give_to_singleplayer = false}
)

function round(val, decimal)
    if (decimal) then
        return math.floor( (val * 10^decimal) + 0.5) / (10^decimal)
    else
        return math.floor(val+0.5)
    end
end

local send_volcano_state = function(pos, name)
	local volc = get_volcano(pos)
	if volc == nil then
		return false
	end
	local location = {x=math.floor(volc.location.x), y=volc.depth_peak, z=math.floor(volc.location.z)}
	local text = "Peak at " .. minetest.pos_to_string(location)
		.. ", Slope: " .. tostring(round(volc.slope, 2))
		.. ", State: "
	if volc.state < state_extinct then
		text = text .. "Extinct"
	elseif volc.state < state_dormant then
		text = text .. "Dormant"
	else
		text = text .. "Active"
	end

	minetest.chat_send_player(name, text)
	return true
end

local send_nearby_states = function(pos, name)
	local retval = false
	retval = send_volcano_state({x=pos.x-volcano_region_size, y=0, z=pos.z+volcano_region_size}, name) or retval
	retval = send_volcano_state({x=pos.x, y=0, z=pos.z+volcano_region_size}, name) or retval
	retval = send_volcano_state({x=pos.x+volcano_region_size, y=0, z=pos.z+volcano_region_size}, name) or retval
	retval = send_volcano_state({x=pos.x-volcano_region_size, y=0, z=pos.z}, name) or retval
	retval = send_volcano_state(pos, name) or retval
	retval = send_volcano_state({x=pos.x+volcano_region_size, y=0, z=pos.z}, name) or retval
	retval = send_volcano_state({x=pos.x-volcano_region_size, y=0, z=pos.z-volcano_region_size}, name) or retval
	retval = send_volcano_state({x=pos.x, y=0, z=pos.z-volcano_region_size}, name) or retval
	retval = send_volcano_state({x=pos.x+volcano_region_size, y=0, z=pos.z-volcano_region_size}, name) or retval
	return retval
end

minetest.register_chatcommand(
    "findvolcanoes", {
        params = "pos", -- Short parameter description
        description = "find the volcanoes near the player's map region, or in the map region containing pos if provided",
        privs = {findvolcano = true},
        func = function(name, param)
            local pos = {}
            pos.x, pos.y, pos.z = string.match(param, "^([%d.-]+)[, ] *([%d.-]+)[, ] *([%d.-]+)$")
            pos.x = tonumber(pos.x)
            pos.y = tonumber(pos.y)
            pos.z = tonumber(pos.z)
            if pos.x and pos.y and pos.z then
                if not send_nearby_states(pos, name) then
                    minetest.chat_send_player(name, "No volcanoes near " .. minetest.pos_to_string(pos))
                end
                return true
            else
                local playerobj = minetest.get_player_by_name(name)
                pos = playerobj:get_pos()
                if not send_nearby_states(pos, name) then
                    pos.x = math.floor(pos.x)
                    pos.y = math.floor(pos.y)
                    pos.z = math.floor(pos.z)
                    minetest.chat_send_player(name, "No volcanoes near " .. minetest.pos_to_string(pos))
                end
                return true
            end
        end,
})
