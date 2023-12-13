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
animals.add_interactors("predators","animals:kubwakubwa","animals:darkasthaan", "animals:sarkamos")
animals.add_interactors("prey","animals:kubwakubwa","animals:pegasun","animals:sneachan", "animals:impethu", "animals:gundu")
animals.add_interactors("rivals","animals:kubwakubwa","animals:kubwakubwa","animals:pegasun_male")

----------------------------------------------
-- Animal Data
local self_data = {
  initial_properties = {
    max_hp = 20,
    
    collisionbox = {-0.14, -0.01, -0.14, 0.14, 0.27, 0.14},
    visual = "mesh",
    mesh = "animals_kubwakubwa.b3d",
    textures = {"animals_kubwakubwa.png"},
    visual_size = {x = 1, y = 1},
  },
  -- animal stats
	lung_capacity = 25,
  oxygen_min = "lung_capacity*0.4",
  breathing_rate = 5,
  -- comfort temps
	min_temp = 7,
	max_temp = 60,
  -- is it land-borne (1), sea-borne (2), amphibious (3), or flying (4)?
  class = 1,
  -- energy
  energy_max = 8000,--secs it can survive without food
  egg_timer = 10,--60*20,
  young_per_egg = {3,4},		--will get this/energy_egg starting energy
  emergency_egg_chance = 0.75,
  -- cannot define conservation minimum + energy_egg (energy_egg being necessary for cn_min) in API due to multiple values needed
  -- lifespan
  lifespan = "energy_max*5",--self_data.energy_max * 5
  mature_age = "energy_max*0.5",
  -- settings
  max_pop = 23,
  -- interactions
  -- predators + rivals automatically defined in registration
  capture_interactions = {
    club = 0.55,
  },
  -- logic for mobkit
  logic = brain,
  --movement
	springiness=0,
	buoyancy = 1.01,
	max_speed = 0.75,					-- m/s
	jump_height = 1.5,				-- nodes/meters
	view_range = 10,					-- nodes/meters
	--attack
	attack={range=0.4, damage_groups={fleshy=4}},
	armor_groups = {fleshy=100},
  -- animation + sounds
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
  -- on actions
  drops = {
		{name = "animals:carcass_invert_large", chance = 1, min = 1, max = 1,},
	},
	on_punch=function(self, puncher, time_from_last_punch, tool_capabilities, dir)
		animals.on_punch(self, tool_capabilities, puncher, 55, 0.75)
	end,
	on_rightclick = function(self, clicker)
		animals.stun_catch_mob(self, clicker, 0.1)
	end,
  _on_death = function(self, pos)
    local good_temp,temp_status = animals.temp_comfy(self)
    if good_temp or temp_status ~= "cold" then
      return
    end
    animals.emergency_egg(self, pos)
  end,
  -- eggs
  egg = {
    name = "animals:kubwakubwa_eggs",
    description = S('Kubwakubwa Eggs'),
    tiles = {"animals_kubwakubwa_eggs.png"},
    node_box = {
      type = "fixed",
      fixed = {-0.0625, -0.5, -0.0625,  0.0625, -0.375, 0.0625},
    },
    _conditions_correct = function(pos,egg_data)
      if not egg_data then return false,true end -- break egg
      local egg_timer = egg_data.egg_timer
      local temp = climate.get_point_temp(pos)
      if (temp < 12) then
        -- too cold to hatch, wait again (with increased time)
        return false,math.random(egg_timer,egg_timer*3)
      end
      return true
    end,
  },
  -- spawnegg or live animal
  spawnegg = {
    desc = S("Live Kubwakubwa"),
    inv_img = "animals_kubwakubwa_item.png",
    stack = minimal.stack_max_medium
  },
}
self_data.energy_egg = self_data.energy_max*0.5 --energy that goes to egg
self_data.cn_min = (self_data.energy_egg / self_data.young_per_egg[2]) * 0.4 -- conserve min (minimum point at when to conserve energy)
self_data = animals.register_animal("animals:kubwakubwa",self_data)
