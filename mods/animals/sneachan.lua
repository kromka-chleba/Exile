----------------------------------------------------------------------
-- Sneachan
--small insect.
--[[
Land living
Dislikes bright light, eats sediment, plants,
]]
---------------------------------------------------------------------

-- Internationalization
local S = animals.S

local random = math.random
local floor = math.floor



-----------------------------------
local function brain(self)
  -- calculate instantanious effects
  animals.core_hp(self)
  
	if mobkit.timer(self,1) then

		local pos = mobkit.get_stand_pos(self)

		local age, energy = animals.core_life(self, pos)
		--die from exhaustion or age
		if not age then
			return
		end

		------------------
		--Emergency actions


		local prty = mobkit.get_queue_priority(self)
		-------------------
		--High priority actions
		local pred

		if prty < 50 then


			--Threats
			local plyr = animals.get_nearby_player(self)
			if plyr then
				animals.fight_or_flight_plyr(self, plyr, 55, 0.01)
			end

			pred = animals.predator_avoid(self, 55, 0.01)

		end


		----------------------
		--Low priority actions

		if prty < 20 then

			--territorial behaviour
			local rival = animals.territorial(self, energy, true)


			--feeding
			local light = (minetest.get_node_light(pos) or 0)

			if light <= 12 then
				--hungry eat stuff in the dark
				if energy < self.energy_max then
					if animals.eat_grassy_sediment_under(pos, 0.001) == true then
						energy = energy + 4
					elseif  animals.eat_flora(pos, 0.001) == true then
						energy = energy + 7
					else
						--wander random
						mobkit.animate(self,'walk')
						--mobkit.hq_roam(self,10)
						animals.hq_roam_surface_group(self, 'spreading', 20)
					end
				else
					--full
					mobkit.hq_roam(self,1)
				end
			elseif random()<0.5 and energy < self.energy_max then
				--slower, less effective feeding during day
				if animals.eat_grassy_sediment_under(pos, 0.001) then
					energy = energy + 1
				elseif  animals.eat_flora(pos, 0.001) then
					energy = energy + 3
				else
					--wander random
					mobkit.animate(self,'walk')
					animals.hq_roam_dark(self,10)
				end
			else
				--get out of the light
				animals.hq_roam_dark(self,15)
			end




			--reproduction
			--asexual parthogenesis, eggs
			if random() < 0.005
			and not rival
			and not pred
			and self.hp >= self.max_hp
			and energy >= (self.energy_max * 0.8) then
				energy = animals.place_egg(self, pos, energy)
			end

		end

		-------------------
		--generic behaviour
		if mobkit.is_queue_empty_high(self) then
			mobkit.animate(self,'walk')
			animals.hq_roam_dark(self,10,1)
		end

		-----------------
		--housekeeping
		--save energy, age
		mobkit.remember(self,'energy',energy)
		mobkit.remember(self,'age',age)

	end
end






---------------
-- the CREATURE
---------------

----------------------------------------------
-- SETTING OF SNEACHAN INTERACTOR SETTINGS
animals.add_interactors("predators","sneachan","animals:pegasun", "animals:pegasun_male", "animals:kubwakubwa", "animals:darkasthaan")
animals.add_interactors("rivals","sneachan","animals:sneachan", "animals:impethu")

----------------------------------------------
--The Animal
local self_data = {
  name = "animals:sneachan",
  --core
	physical = true,
	collide_with_objects = true,
	collisionbox = {-0.1, -0.01, -0.1, 0.1, 0.15, 0.1},
	visual = "mesh",
	mesh = "animals_sneachan.b3d",
	textures = {"animals_sneachan.png"},
	visual_size = {x = 1, y = 1},
	makes_footstep_sound = true,
	timeout = 0,

	-- animal stats
	max_hp = 3,
	lung_capacity = 10,
  -- comfort temps
	min_temp = 1,
	max_temp = 50,
  -- is it land-borne (1), sea-borne (2), amphibious (3), or flying (4)?
  class = 1,
  
  --movement
	springiness=0,
	buoyancy = 1.01,
	max_speed = 1,					-- m/s
	jump_height = 1,				-- nodes/meters
	view_range = 2,					-- nodes/meters

	--attack
	attack={range=0.3, damage_groups={fleshy=1}},
	armor_groups = {fleshy=100},

	--interaction
	predators = animals.get_interactors("sneachan","predators"),
	rivals = animals.get_interactors("sneachan","rivals"),
  
  -- settings
  max_pop = 20,

	on_step = mobkit.stepfunc,
	on_activate = mobkit.actfunc,
	get_staticdata = mobkit.statfunc,
	logic = brain,
	-- optional mobkit props
	-- or used by built in behaviors
	--physics = [function user defined] 		-- optional, overrides built in physics
	animation = {
		walk={range={x=0, y=20}, speed=20, loop=true},
		fast={range={x=0, y=20}, speed=40, loop=true},
		stand={range={x=0, y=20}, speed=10, loop=true},
    dead = {range ={x=0, y=0},speed = 0,loop=true},
	},
	sounds = {
		warn = {
			name = "animals_sneachan_warn",
			gain={0.05, 0.2},
			fade={0.5, 1.5},
			pitch={0.6, 1.3},
		},
		punch = {
			name = "animals_punch",
			gain={0.3, 0.9},
			fade={0.5, 1.5},
			pitch={0.5, 1.5},
		},
	},

	--on actions
	drops = {
		{name = "animals:carcass_invert_small", chance = 1, min = 1, max = 1,},
	},
	on_punch=function(self, puncher, time_from_last_punch, tool_capabilities, dir)
		animals.on_punch(self, tool_capabilities, puncher, 55, 0.1)
	end,
	on_rightclick = function(self, clicker)
		if not clicker or not clicker:is_player() then
			return
		end
		animals.stun_catch_mob(self, clicker, 0.75, true)
	end,
  on_death = function(self, pos)
    local good_temp,temp_status = animals.temp_comfy(self)
    if good_temp or temp_status ~= "cold" then
      return
    end
    animals.emergency_egg(self, pos)
  end
}
---- ADDITIONAL VARIABLES (requires variables to be pre-defined for calculations of other variables)
-- energy and eggs
self_data.energy_max = 5000--secs it can survive without food
self_data.energy_egg = (self_data.energy_max*0.5) --energy that goes to egg
self_data.egg_timer = 60*10
self_data.young_per_egg = {3,7}		--will get this/energy_egg starting energy
self_data.emergency_egg_chance = 0.6
-- lifespan
self_data.lifespan = self_data.energy_max * 5
---------------------;
minetest.register_entity("animals:sneachan",self_data)

----------------------------------------------
--eggs
minetest.register_node("animals:sneachan_eggs", {
	description = S('Sneachan Eggs'),
	tiles = {"animals_sneachan_eggs.png"},
	stack_max = minimal.stack_max_medium,
	drawtype = "nodebox",
	paramtype = "light",
	node_box = {
		type = "fixed",
		fixed = {-0.08, -0.5, -0.08,  0.08, -0.4375, 0.08},
	},
	groups = {snappy = 3, falling_node = 1, dig_immediate = 3, flammable = 1, temp_pass = 1, edible = 1, egg = 1},
	sounds = nodes_nature.node_sound_defaults(),
	on_construct = function(pos)
    local egg_timer = self_data.egg_timer
		minetest.get_node_timer(pos):start(math.random(egg_timer,egg_timer*2))
	end,
	on_timer =function(pos, elapsed)
    local egg_timer = self_data.egg_timer
    local energy_egg = self_data.energy_egg
    local young_per_egg = self_data.young_per_egg
    
    local temp = climate.get_point_temp(pos)
    if (temp < 10 ) then
      -- don't hatch and keep timer going if temp is too uncomfortably cold
      minetest.get_node_timer(pos):start(math.random(egg_timer,egg_timer*4))
      return false
    end
		local light = (minetest.get_node_light(pos) or 0)
		if light <= 10 then
			return animals.hatch_egg(self_data, pos)
		else
			if random()<0.3 then
				return animals.hatch_egg(self_data, pos)
			end
      minetest.get_node_timer(pos):start(math.random(egg_timer,egg_timer*2)) -- return a regular egg_timer
			return false
		end
	end,
})





--spawn egg (i.e. live animal in inventory)
animals.register_egg(self_data, S("Live Sneachan"), "animals_sneachan_item.png", minimal.stack_max_medium)
