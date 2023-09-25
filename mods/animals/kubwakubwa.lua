----------------------------------------------------------------------
-- Kubwakubwa
--a spider
--[[
Predator in shallow caves
]]

---------------------------------------------------------------------

-- Internationalization
local S = animals.S

local random = math.random
local floor = math.floor


-----------------------------------
local function brain(self)
	if mobkit.timer(self,1) then

		local pos = mobkit.get_stand_pos(self)

		local age, energy, conserve = animals.core_life(self, self.lifespan, pos)
		--die from exhaustion or age
		if not age then
			return
		end

		------------------
		--Emergency actions

		--swim to shore
		if self.isinliquid then
			mobkit.hq_liquid_recovery(self,60)
		end


		local prty = mobkit.get_queue_priority(self)
		-------------------
		--High priority actions
		if prty < 50 then

			--Threats
			local plyr = animals.get_nearby_player(self)
			if plyr then
        prty = 55
				animals.fight_or_flight_plyr(self, plyr, prty, 0.15)
			end

			if (animals.predator_avoid(self, 55, 0.15) or plyr) then
        prty = 55
        conserve = false -- on the move, no more conserving
      end

		end


		----------------------
		--Low priority actions

		if prty < 20 and conserve ~= true then

			--territorial behaviour
			local rival = animals.territorial(self, energy, true)


			--feeding
			--hunt prey
			if energy < self.energy_max then
				if not animals.prey_hunt(self, 25) then
					--random search for darkness
					animals.hq_roam_dark(self,15)
          
          if (energy <= self.cn_min) then
            conserve = true
          end
				end
			end

			--reproduction
			--asexual parthogenesis, eggs
			--when in prime condition
			if random() < 0.1
			and not rival
			and self.hp >= self.max_hp
			and energy >= self.energy_egg + 100
      and age >= self.mature_age then
				energy = animals.place_egg(self, pos, energy)
			end
    elseif (conserve == true) then
      if (animals.prey_hunt(self,40)) then
        conserve = false -- found prey, get out of hibernation
      end
		end

		-------------------
		--generic behaviour
		if mobkit.is_queue_empty_high(self) and conserve ~= true then
			mobkit.animate(self,'walk')
			animals.hq_roam_dark(self,10,1)
		end
    
		-----------------
		--housekeeping
		--save energy, age
		mobkit.remember(self,'energy',energy)
		mobkit.remember(self,'age',age)
    mobkit.remember(self,'conserve',conserve)

	end
end




---------------
-- the CREATURE
---------------

----------------------------------------------
-- SETTING OF KUBWAKUBWA INTERACTOR SETTINGS
animals.add_interactors("predators","kubwakubwa","animals:darkasthaan", "animals:sarkamos")
animals.add_interactors("prey","kubwakubwa","animals:pegasun","animals:sneachan", "animals:impethu")
animals.add_interactors("rivals","kubwakubwa","animals:kubwakubwa","animals:pegasun_male")


----------------------------------------------
--The Animal
local self_data = {
  name = "animals:kubwakubwa",
	--core
	physical = true,
	collide_with_objects = true,
	collisionbox = {-0.14, -0.01, -0.14, 0.14, 0.27, 0.14},
	visual = "mesh",
	mesh = "animals_kubwakubwa.b3d",
	textures = {"animals_kubwakubwa.png"},
	visual_size = {x = 1, y = 1},
	makes_footstep_sound = true,
	timeout = 0,


	-- animal stats
	max_hp = 20,
	lung_capacity = 20,
  -- comfort temps
	min_temp = 7,
	max_temp = 56,
  -- is it land-borne (1), sea-borne (2), amphibious (3), or flying (4)?
  class = 1,
  
  -- settings
  max_pop = 23,

	on_step = mobkit.stepfunc,
	on_activate = mobkit.actfunc,
	get_staticdata = mobkit.statfunc,
	logic = brain,
	-- optional mobkit props
	-- or used by built in behaviors
	--physics = [function user defined] 		-- optional, overrides built in physics
	animation = {
		walk={range={x=0,y=20},speed=20,loop=true},
		fast={range={x=0,y=20},speed=50,loop=true},
		stand={range={x=20,y=40},speed=10,loop=true},
    dead = {range ={x=0, y=0},speed = 0,loop=true},
	},
	sounds = {
		warn = {
			name = "animals_kubwakubwa_warn",
			gain={0.4, 0.8},
			fade={0.5, 1.5},
			pitch={0.9, 1.1},
		},
		punch = {
			name = "animals_punch",
			gain={0.5, 1},
			fade={0.5, 1.5},
			pitch={0.5, 1.5},
		},
	},

	--movement
	springiness=0,
	buoyancy = 1.01,
	max_speed = 0.75,					-- m/s
	jump_height = 1.5,				-- nodes/meters
	view_range = 4,					-- nodes/meters

	--attack
	attack={range=0.4, damage_groups={fleshy=4}},
	armor_groups = {fleshy=100},
  
  --interaction
	predators = animals.get_interactors("kubwakubwa","predators"),
	rivals = animals.get_interactors("kubwakubwa","rivals"),
	prey = animals.get_interactors("kubwakubwa","prey"),

	--on actions
	drops = {
		{name = "animals:carcass_invert_large", chance = 1, min = 1, max = 1,},
	},
	on_punch=function(self, puncher, time_from_last_punch, tool_capabilities, dir)
		animals.on_punch(self, tool_capabilities, puncher, 55, 0.75)
	end,
	on_rightclick = function(self, clicker)
		if not clicker or not clicker:is_player() then
			return
		end
		animals.stun_catch_mob(self, clicker, 0.1)
	end,
}
---- ADDITIONAL VARIABLES (requires variables to be pre-defined for calculations of other variables)
-- energy and eggs
self_data.energy_max = 8000   --secs it can survive without food
self_data.energy_egg = self_data.energy_max/2  --energy that goes to egg
self_data.egg_timer = 60*20
self_data.young_per_egg = {3,4}   --will get this/energy_egg starting energy
self_data.cn_min = (self_data.energy_egg / self_data.young_per_egg[2]) * 0.4 -- conserve min (minimum point at when to conserve energy)
-- lifespan
self_data.lifespan = self_data.energy_max * 6
self_data.mature_age = self_data.energy_max/2
---------------------;
minetest.register_entity("animals:kubwakubwa",self_data)

----------------------------------------------
--eggs
minetest.register_node("animals:kubwakubwa_eggs", {
	description = S('Kubwakubwa Eggs'),
	tiles = {"animals_kubwakubwa_eggs.png"},
	stack_max = minimal.stack_max_medium,
	drawtype = "nodebox",
	paramtype = "light",
	node_box = {
		type = "fixed",
		fixed = {-0.0625, -0.5, -0.0625,  0.0625, -0.375, 0.0625},
	},
	groups = {snappy = 3, falling_node = 1, dig_immediate = 3, flammable = 1, temp_pass = 1, edible = 1, egg = 1},
	sounds = nodes_nature.node_sound_defaults(),
	on_construct = function(pos)
    local egg_timer = self_data.egg_timer
		minetest.get_node_timer(pos):start(math.random(egg_timer,egg_timer*2))
	end,
	on_timer = function(pos, elapsed)
    local egg_timer = self_data.egg_timer
    local energy_egg = self_data.energy_egg
    local young_per_egg = self_data.young_per_egg
    
    local temp = climate.get_point_temp(pos)
    
    if (temp < 14) then
      -- too cold to hatch, wait again
      minetest.get_node_timer(pos):start(math.random(egg_timer,egg_timer*3))
      return false
    end
    
    return animals.hatch_egg(self_data, pos)
	end,
})




--spawn egg (i.e. live animal in inventory)
animals.register_egg("animals:kubwakubwa", S("Live Kubwakubwa"), "animals_kubwakubwa_item.png", minimal.stack_max_medium, self_data)
