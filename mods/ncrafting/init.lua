--
local modpath = minetest.get_modpath('nodecrafting')


ncrafting = {
 base_firing = 25,
 firing_int = 10,
 cook_rate = 6   -- cook timer; tenth of a minute seems fine
}

-- Internationalization
ncrafting.S = minetest.get_translator("nodecrafting")

dofile(modpath..'/dyes.lua')
dofile(modpath..'/nature.lua')
dofile(modpath..'/arches.lua')
dofile(modpath..'/switches.lua')
dofile(modpath..'/fermentation.lua')

local store = minetest.get_mod_storage()

function ncrafting.loadstore(name)
   return minetest.deserialize(store:get_string(name))
end
function ncrafting.savestore(name, table)
   store:set_string(name, minetest.serialize(table))
end
function ncrafting.loadstore64(name)
   local decodeme = minetest.decode_base64(store:get_string(name))
   return minetest.deserialize(decodeme)
end
function ncrafting.savestore64(name, table)
   local encodeme = minetest.serialize(table)
   store:set_string(name, minetest.encode_base64(encodeme))
end

-----------------------------------------------
-- Smoke particles

function ncrafting.particle_smokesmall(pos)
   return {
  amount = 2,
  time = 0.5,
  minpos = {x = pos.x - 0.1, y = pos.y, z = pos.z - 0.1},
  maxpos = {x = pos.x + 0.1, y = pos.y + 0.5, z = pos.z + 0.1},
  minvel = {x= 0, y= 0, z= 0},
  maxvel = {x= 0.01, y= 0.06, z= 0.01},
  minacc = {x= 0, y= 0, z= 0},
  maxacc = {x= 0.01, y= 0.1, z= 0.01},
  minexptime = 3,
  maxexptime = 10,
  minsize = 1,
  maxsize = 4,
  collisiondetection = true,
  vertical = true,
  texture = "tech_smoke.png",
   }
end

-----------------------------------------------
-- Roasting functions
-- Used for basic things like iron that don't
--  shatter or burn, but can optionally get wet

function ncrafting.set_roast(pos, length, interval)
	-- and firing count
	local meta = minetest.get_meta(pos)
	meta:set_int("roast", length)
	--check heat interval
	minetest.get_node_timer(pos):start(interval)
end

function ncrafting.roast(pos, selfname, name, length, heat, wet_result)
	local meta = minetest.get_meta(pos)
	local roast = meta:get_int("roast")

	--check if wet stop
	if climate.get_rain(pos) or minetest.find_node_near(pos, 1, {"group:water"}) then
	   if wet_result then
	      minetest.set_node(pos, {name = wet_result})
	      return true
	   else -- nothing happens, just no progress this round
	      return false
	   end
	end

	--exchange accumulated heat
	climate.heat_transfer(pos, selfname)

	--check if above firing temp
	local temp = climate.get_point_temp(pos)
	local fire_temp = heat

	if roast <= 0 then
	   --finished firing
	   minetest.set_node(pos, {name = name})
	   minetest.check_for_falling(pos)
	   return false
	elseif temp < fire_temp then
	   --not lit yet
	   return true
	elseif temp >= fire_temp then
	   --do firing
	   meta:set_int("roast", roast - 1)
	   return true
	end
end




-----------------------------------------------
-- Pottery firing functions

function ncrafting.set_firing(pos, length, interval)
	-- and firing count
	local meta = minetest.get_meta(pos)
	meta:set_int("firing", length)
	--check heat interval
	minetest.get_node_timer(pos):start(interval)
end

function ncrafting.on_dig_pottery(pos, node, digger, length)
	local meta = minetest.get_meta(pos)
	local firing = meta:get_int("firing")
	if firing < length and firing > 0 then
	   node.name = "tech:broken_pottery"
	   digger:punch(digger, 1, {full_punch_interval = 1,  -- OOH, BURN!
				    damage_groups = { fleshy = 1 }, nil })
	   minetest.set_node(pos, node)
	else
	   core.node_dig(pos, node, digger)
	end
end

function ncrafting.fire_pottery(pos, selfname, name, length, firing_temp)
	local meta = minetest.get_meta(pos)
	local firing = meta:get_int("firing")

	--check if wet, falls to bits and thats it for your pot
	if climate.get_rain(pos) or minetest.find_node_near(pos, 1, {"group:water"}) then
		minetest.set_node(pos, {name = 'nodes_nature:clay_wet'})
		return false
	end

	--exchange accumulated heat
	climate.heat_transfer(pos, selfname)

	--check if above firing temp
	local temp = climate.get_point_temp(pos)
	local fire_temp = firing_temp or 600

	if firing <= 0 then
		--finished firing
		minimal.switch_node(pos, {name = name})
		return false
	elseif temp < fire_temp then
		if firing < length and temp < fire_temp/2 then
			--firing began but is now interupted
			--causes firing to fail
			minetest.set_node(pos, {name = "tech:ruined_pottery_slab"})
			return false
		else
			--no fire lit yet
			return true
		end
	elseif temp >= fire_temp then
		--do firing
		meta:set_int("firing", firing - 1)
		return true
	end

end


-----------------------------------------------
-- Baking functions

function ncrafting.start_bake(pos, result)
   local meta = minetest.get_meta(pos)
   meta:set_int("baking", result)
   minetest.get_node_timer(pos):start(ncrafting.cook_rate)
end

function ncrafting.do_bake(pos, elapsed, heat, length, cookname, burnname)
   local selfname = minetest.get_node(pos).name
   selfname = selfname:gsub("_cooked","") -- ensure we have the base name
   local name_cooked = cookname or selfname.."_cooked"
   local name_burned = burnname or selfname.."_burned"
   local burntime = math.floor( length * .40 + 10 ) * -1
   local meta = minetest.get_meta(pos)
   local baking = meta:get_int("baking")

   --check if wet, wait until dry
   if climate.get_rain(pos) or minetest.find_node_near(pos, 1, {"group:water"}) then
      return true
   end

   --exchange accumulated heat
   climate.heat_transfer(pos, selfname)

   --check if above firing temp
   local temp = climate.get_point_temp(pos)
   local fire_temp = heat
   if temp == nil then
      return true
   elseif baking == 0 then
      --finished firing
      minimal.switch_node(pos, {name = name_cooked})
      ncrafting.set_treatment(meta, "cook")
      minetest.check_for_falling(pos)
      local cook_def = minetest.registered_nodes[name_cooked]
      if HEALTH.bake_table[name_cooked] and cook_def and cook_def.on_construct then
        cook_def.on_construct(pos)
        return false
      end
      meta:set_int("baking", -1) -- prepare to burn it
      minetest.get_node_timer(pos):start(ncrafting.cook_rate)
      return true
   elseif temp < fire_temp then
      --not lit yet
      return true
   elseif temp > fire_temp * 2  or baking < burntime then
      if minetest.registered_nodes[name_burned] then
	 --too hot or too long on the fire, burn
	 minetest.swap_node(pos, {name = name_burned})
	 ncrafting.set_treatment(meta, "burn")
      else
	 minetest.set_node(pos, {name = "air"})
      end
      --Smoke
      minetest.sound_play("tech_fire_small",{pos=pos, max_hear_distance = 10, loop=false, gain=0.1})
      minetest.add_particlespawner(ncrafting.particle_smokesmall(pos))
      return false
   elseif temp >= fire_temp then -- do baking
      meta:set_int("baking", baking - 1)
      return true
   end
end


-----------------------------------------------
-- Soaking/Retting functions

function ncrafting.start_soak(pos, length, interval)
   local meta = minetest.get_meta(pos)
   meta:set_int("soaking", length)
   minetest.get_node_timer(pos):start(interval)
end

function ncrafting.do_soak(pos, name, interval, catchup, detectfunc)
  local can_soak = minimal.shift_pos(pos,{y=1})
  if type(detectfunc) == "function" then
    -- specify a different set of variables, sends above pos as parameter
    -- e.g. could check temp or specify a different liquid and return true or false depending on conditions met
    can_soak = detectfunc(can_soak)
  else
    -- usual water on top
    can_soak = minetest.registered_nodes[minetest.get_node(can_soak).name]
    -- if registered, has groups, and has water group equaling 1 (freshwater)
    can_soak = can_soak and can_soak.groups and can_soak.groups.water == 1
  end
  if can_soak then
    local meta = minetest.get_meta(pos)
    local soaking = meta:get_int("soaking")
    -- option to calculate soaking via nodetimer elapsed and nodetimer interval
    soaking = (type(interval) == "number" and type(catchup) == "number") and soaking-math.floor(catchup/interval)
    or soaking - 1
    meta:set_int("soaking",soaking)
    if soaking <= 0 then
      -- finished
      minimal.switch_node(pos, {name = name})
      ncrafting.set_treatment(meta, "soak")
      return false
    end
  end
  -- can_soak was not true (no water, unless condition was specified with other parameters with detectfunc)
  return true
end

minetest.register_abm({
      label = "node timer restart",
      nodenames = "group:timer",
      interval = 23,
      chance = 10,
      action = function(pos, node, active_object_count, active_object_count_wider)
	 local timer = minetest.get_node_timer(pos)
	 if not timer:is_started() then
	    timer:start(minetest.registered_nodes[node.name].groups.timer)
	 end
      end,
})
