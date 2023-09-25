----------------------------------------------------------------------
-- Darkasthaan

--[[
a big spider for deep caves
much same as kubwakubwa, but more dangerous
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

		local age, energy, conserve = animals.core_life(self, pos)
		--die from exhaustion or age
		if not age then
			return
		end

		------------------
		--Emergency actions

		local prty = mobkit.get_queue_priority(self)
		-------------------
		--High priority actions
		if prty < 50 then


			--Threats
			local plyr = animals.get_nearby_player(self)
			if plyr then
        prty = 55
				animals.fight_or_flight_plyr(self, plyr, prty, 0.75)
        conserve = false -- not hibernating anymore
			end

			--currently has none
			--animals.predator_avoid(self, 55, 0.75)
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
			and energy >= self.energy_egg*2
      and age >= self.mature_age then
				energy = animals.place_egg(self, pos, energy)
			end
    elseif (conserve == true) then
      if animals.prey_hunt(self,40) then -- if found food then get outta hibernation
        conserve = false
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
    mobkit.remember(self,'conserve',conserve) -- to prevent energy loss with no prey around

	end
end






---------------
-- the CREATURE
---------------

----------------------------------------------
-- SETTING OF DARKASTHAAN INTERACTOR SETTINGS
animals.add_interactors("prey","darkasthaan","animals:impethu", "animals:kubwakubwa", "animals:pegasun", "animals:pegasun_male", "animals:sneachan", "animals:gundu")
animals.add_interactors("rivals","darkasthaan","animals:darkasthaan")

----------------------------------------------
--The Animal
local self_data = {
  name = "animals:darkasthaan",
	--core
	physical = true,
	collide_with_objects = true,
	collisionbox = {-0.3, -0.3, -0.3, 0.3, 0, 0.3},
	visual = "mesh",
	mesh = "animals_darkasthaan.b3d",
	textures = {"animals_darkasthaan.png"},
	visual_size = {x = 0.6, y = 0.6},
	makes_footstep_sound = true,
	timeout = 0,

	-- animal stats
	max_hp = 200,
	lung_capacity = 40,
  breathing_rate = 8,
  -- comfort temps
	min_temp = 14,
	max_temp = 66,
  -- is it land-borne (1), sea-borne (2), amphibious (3), or flying (4)?
  class = 1,

	on_step = mobkit.stepfunc,
	on_activate = mobkit.actfunc,
	get_staticdata = mobkit.statfunc,
	logic = brain,
	-- optional mobkit props
	-- or used by built in behaviors
	--physics = [function user defined] 		-- optional, overrides built in physics
	animation = {
		walk={range={x=1,y=21},speed=15,loop=true},
		fast={range={x=1,y=21},speed=35,loop=true},
		stand={range={x=25,y=45},speed=5,loop=true},
    dead = {range ={x=0, y=0},speed = 0,loop=true},
	},
	sounds = {
		warn = {
			name = "animals_darkasthaan_warn",
			gain={0.3, 0.7},
			fade={0.5, 1.5},
			pitch={0.4, 1.4},
		},
		punch = {
			name = "animals_punch",
			gain={0.7, 1.3},
			fade={0.5, 1.5},
			pitch={0.7, 1.3},
		},
	},

	--movement
	springiness=0,
	buoyancy = 1.01,
	max_speed = 1,					-- m/s
	jump_height = 2,				-- nodes/meters
	view_range = 6,					-- nodes/meters

	--attack
	attack={range=0.8, damage_groups={fleshy=12}},
	armor_groups = {fleshy=100},
  
  --interaction
	rivals = animals.get_interactors("darkasthaan","rivals"),
	prey = animals.get_interactors("darkasthaan","prey"), 

	--on actions
	drops = {
		{name = "animals:carcass_invert_large", chance = 1, min = 1, max = 1,},
	},
	on_punch=function(self, puncher, time_from_last_punch, tool_capabilities, dir)
		animals.on_punch(self, tool_capabilities, puncher, 55, 0.85)
	end,
	on_rightclick = function(self, clicker)
		if not clicker or not clicker:is_player() then
			return
		end
		animals.stun_catch_mob(self, clicker, 0.02)
	end,
}
---- ADDITIONAL VARIABLES (requires variables to be pre-defined for calculations of other variables)
-- energy and eggs
self_data.energy_max = 12000   --secs it can survive without food
self_data.energy_egg = self_data.energy_max/3  --energy that goes to egg
self_data.egg_timer = 60*30
self_data.young_per_egg = {1,3}   --will get this/energy_egg starting energy
self_data.cn_min = (self_data.energy_egg / self_data.young_per_egg[2]) * 0.7 -- conserve min (minimum point at when to conserve energy)
-- 70% of the energy given to a newborn
-- lifespan
self_data.lifespan = self_data.energy_max * 7
self_data.mature_age = self_data.lifespan / 10
---------------------;
minetest.register_entity("animals:darkasthaan",self_data)

----------------------------------------------
--eggs
minetest.register_node("animals:darkasthaan_eggs", {
	description = S('Darkasthaan Eggs'),
	tiles = {"animals_darkasthaan_eggs.png^[resize:4x16"},
	stack_max = minimal.stack_max_medium,
	drawtype = "nodebox",
	paramtype = "light",
	node_box = {
		type = "fixed",
		fixed = {-0.125, -0.5, -0.125,  0.125, -0.375, 0.125},
	},
	groups = {snappy = 3, falling_node = 1, dig_immediate = 3, flammable = 1, temp_pass = 1, edible = 1, egg = 1},
	sounds = nodes_nature.node_sound_defaults(),
	on_construct = function(pos)
    local egg_timer = self_data.egg_timer
		minetest.get_node_timer(pos):start(math.random(egg_timer,egg_timer*2))
	end,
	on_timer =function(pos, elapsed)
    local energy_egg = self_data.energy_egg
    local young_per_egg = self_data.young_per_egg
    
		return animals.hatch_egg(self_data, pos)
	end,
})




--spawn egg (i.e. live animal in inventory)
animals.register_egg(self_data, S("Live Darkasthaan"), "animals_darkasthaan_item.png", minimal.stack_max_medium)
