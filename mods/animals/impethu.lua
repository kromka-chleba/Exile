----------------------------------------------------------------------
-- Impethu
--cave worm.
--[[
Bottom of shallow cave food chain
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

		local age, energy = animals.core_life(self, self.lifespan, pos)
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
				animals.fight_or_flight_plyr(self, plyr, 55, 0.02)
			end

			pred = animals.predator_avoid(self, 55, 0.02)

		end


		----------------------
		--Low priority actions

		if prty < 20 then

			--territorial behaviour
			local rival
			if random() < 0.7 then
				rival = animals.territorial(self, energy, false)
			else
				rival = animals.territorial(self, energy, true)
			end


			--feeding
			--eat stuff in the dark
			local light = (minetest.get_node_light(pos) or 0)

			if light <= 5 then
				if not rival and energy < self.energy_max then
					energy = energy + random(2,6)
				end
				mobkit.animate(self,'walk')
				mobkit.hq_roam(self,10)
			else
				--random search for darkness
				--fatigued by light
				energy = energy - random(2,6)
				animals.hq_roam_dark(self,15)
			end


			--reproduction
			--asexual parthogenesis, eggs
			if random() < 0.005 then
				if not rival
				and energy >= self.energy_max then
					energy = animals.place_egg(self, pos, energy)
				end
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

-- SETTING OF IMPETHU INTERACTOR SETTINGS
animals.add_interactors("predators","impethu","animals:pegasun", "animals:pegasun_male", "animals:kubwakubwa", "animals:darkasthaan")
animals.add_interactors("rivals","impethu","animals:sneachan", "animals:impethu")

----------------------------------------------
-- The Animal
local self_data = {
  name = "animals:impethu",
	--core
	physical = true,
	collide_with_objects = true,
	collisionbox = {-0.09, -0.25, -0.09, 0.09, -0.1, 0.09},
	visual = "mesh",
	mesh = "animals_impethu.b3d",
	textures = {"animals_impethu.png"},
	visual_size = {x = 5, y = 5},
	makes_footstep_sound = false,
	timeout = 0,

	-- animal stats
	max_hp = 3,
	lung_capacity = 10,
  -- comfort temps
	min_temp = 10,
	max_temp = 68,
  -- is it land-borne (1), sea-borne (2), amphibious (3), or flying (4)?
  class = 1,
  
  -- settings
  max_pop = 8,

	on_step = mobkit.stepfunc,
	on_activate = mobkit.actfunc,
	get_staticdata = mobkit.statfunc,
	logic = brain,
	-- optional mobkit props
	-- or used by built in behaviors
	--physics = [function user defined] 		-- optional, overrides built in physics
	animation = {
		walk={range={x=0, y=12}, speed=10, loop=true},
		fast={range={x=0, y=12}, speed=10, loop=true},
		stand={
			{range={x=12, y=24}, speed=5, loop=true},
			{range={x=24, y=31}, speed=5, loop=true},
		},
    dead = {range ={x=0, y=0},speed = 0,loop=true},
	},
	sounds = {
		warn = {
			name = "animals_impethu_warn",
			gain={0.1, 0.4},
			fade={0.5, 1.5},
			pitch={0.5, 1.5},
		},
		punch = {
			name = "animals_punch",
			gain={0.5, 1.5},
			fade={0.5, 1.5},
			pitch={0.5, 1.5},
		},
	},

	--movement
	springiness=0,
	buoyancy = 1.01,
	max_speed = 0.5,					-- m/s
	jump_height = 1,				-- nodes/meters
	view_range = 2,					-- nodes/meters

	--attack
	attack={range=0.3, damage_groups={fleshy=1}},
	armor_groups = {fleshy=100},
  
  --interaction
	predators = animals.get_interactors("impethu","predators"), 
	rivals = animals.get_interactors("impethu","rivals"),

	--on actions
	drops = {
		{name = "animals:carcass_invert_small", chance = 1, min = 1, max = 1,},
	},
	on_punch=function(self, puncher, time_from_last_punch, tool_capabilities, dir)
		animals.on_punch(self, tool_capabilities, puncher, 55, 0.05)
	end,
	on_rightclick = function(self, clicker)
		if not clicker or not clicker:is_player() then
			return
		end
		animals.stun_catch_mob(self, clicker, 0.75, true)
	end,
}
---- ADDITIONAL VARIABLES (requires variables to be pre-defined for calculations of other variables)
-- energy and eggs
self_data.energy_max = 5000   --secs it can survive without food
self_data.energy_egg = self_data.energy_max/10  --energy that goes to egg
self_data.egg_timer = 60*10
self_data.young_per_egg = {2,4}		--will get this/energy_egg starting energy
-- lifespan
self_data.lifespan = self_data.energy_max * 4
---------------------;
minetest.register_entity("animals:impethu",self_data)

----------------------------------------------
--eggs
minetest.register_node("animals:impethu_eggs", {
	description = S('Impethu Eggs'),
	tiles = {"animals_sneachan_eggs.png^[multiply:#c49a82"},
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
    
    if (temp < 14) then
      -- don't hatch and keep timer going if temp is too uncomfortably cold
      minetest.get_node_timer(pos):start(math.random(egg_timer,egg_timer*4))
      return false
    end
    
    local light = (minetest.get_node_light(pos) or 0)
		if light <= 5 then
			return animals.hatch_egg(self_data, pos)
		else
			if random()<0.2 then
				return animals.hatch_egg(self_data, pos)
			end
			minetest.get_node_timer(pos):start(math.random(egg_timer,egg_timer*2)) -- return a regular egg_timer
      return false
		end
	end,
})


--spawn egg (i.e. live animal in inventory)
animals.register_egg("animals:impethu", S("Live Impethu"), "animals_impethu_item.png", minimal.stack_max_medium, self_data)
