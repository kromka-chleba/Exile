----------------------------------------------------------------------
-- Sarkamos
--[[
predator fish
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
		--die from exhaustion or age
		if not animals.core_life(self, pos) then
			return
		end
    local yaw = self.object:get_yaw()
    local nodes = {f=mobkit.pos_translate2d(pos,yaw,1)}
    nodes.fu = animals.node_drawtype(minimal.shift_pos(nodes.f,{y=-1}))
    nodes.f = animals.node_drawtype(nodes.f)
    if (self.energy < self.energy_max and animals.node_drawtype(pos) ~= "airlike")
    and (nodes.f ~= "liquid" or nodes.fu ~= "liquid") then
      self.object:add_velocity({x=0,y=random(10,30)/10,z=0})
      mobkit.clear_queue_high(self)
      mobkit.hq_aqua_turn(self,68,yaw+10,2)
    end


		local prty = mobkit.get_queue_priority(self)
		-------------------
		--High priority actions
		--if prty < 50 then

			--Threats

			--currently none
			--animals.predator_avoid_water(self, 65, 0.01)

		--end


		----------------------
		--Low priority actions
		if prty < 20 then

			--territorial behaviour
			local rival = animals.territorial(self, false)

			--feeding
			if self.energy < self.energy_max then
			   --You are prey
			   local plyr = animals.get_nearby_player(self)
			   if plyr then
			      animals.fight_or_flight(self, plyr, 25, 0.4)
			   end

			   if not animals.prey_hunt(self, 25) then
			      --random search for darkness
			      mobkit.hq_aqua_roam(self,15,self.max_speed/3)
			   end
			end

			if self.energy >= self.energy_max then
			   -- heavy with eggs, sink to look for a laying spot
			   self.object:add_velocity({ x = 0, y = -0.2,
						      z = 0})
			end


			--reproduction
			--asexual parthogenesis, eggs
			--when in prime condition
			--in dark
			local light = minetest.get_node_light(pos, 0.5) or 0
      local tod = animals.timeofday()

			if random() < 0.01
			and not rival
			and light < 10
      and tod == "night"
			and self.hp >= self.max_hp
			and self.energy >= self.energy_max then
			   animals.place_egg(self, pos, 'nodes_nature:salt_water_source')
			end

		end

		-------------------
		--generic behaviour
		if mobkit.is_queue_empty_high(self) then
			mobkit.animate(self,'def')
			mobkit.hq_aqua_roam(self,10,1)
		end
	end
end






---------------
-- the CREATURE
---------------

----------------------------------------------
-- SETTING OF SARKAMOS INTERACTOR SETTINGS
animals.add_interactors("animals:sarkamos","prey", "animals:gundu","animals:pegasun","animals:pegasun_male","animals:kubwakubwa", "animals:darkasthaan")
animals.add_interactors("animals:sarkamos","rivals", "self")

----------------------------------------------
-- Animal Data
local self_data = {
   name = "animals:sarkamos",
	--core
	initial_properties = {
	   max_hp = 200,
	   physical = true,
	   collide_with_objects = true,
	   collisionbox = {-1, -0.65, -1, 1, 0.55, 1},
	   visual = "mesh",
	   mesh = "animals_sarkamos.b3d",
	   textures = {"animals_color_palette.png"},
	   visual_size = {x = 1, y = 1},
	   makes_footstep_sound = false,
	},
	_desc = "Sarkamos",
	timeout = 0,

	-- animal stats
	max_hp = 200,
	lung_capacity = 40,
  -- comfort temps
	min_temp = 0,
	max_temp = 40,
  -- is it land-borne (1), sea-borne (2), or amphibious (3)?
  class = 2,
  -- energy
  energy_max = 14000,--secs it can survive without food
  energy_egg = "energy_max/3", -- energy that goes to egg
  egg_timer = 60*40,
  young_per_egg = {1,3},		--will get this/energy_egg starting energy
  -- lifespan
  lifespan = "energy_max*8",
  -- interactions
  -- prey + rivals automatically defined in registration
  capture_interactions = {
    club = 0.01,
  },
  player_interaction = 1,
  -- logic for mobkit
  logic = brain,
  --movement
	springiness=0.5,
	buoyancy = 1,
	max_speed = 3,					-- m/s
	jump_height = 2,				-- nodes/meters
	view_range = 7,					-- nodes/meters
	--attack
	attack={range=1.5, damage_groups={fleshy=10}},
	armor_groups = {fleshy=100},
  -- animations + sounds
  animation = {
		def={range={x=1,y=40},speed=15,loop=true},
		fast={range={x=40,y=80},speed=20,loop=true},
		stand={range={x=1,y=40},speed=15,loop=true},
    dead = {range ={x=0, y=0},speed = 0,loop=true},
	},
	sounds = {
		flee = {
			name = "animals_water_swish",
			gain={0.5, 1.5},
			fade={0.5, 1.5},
			pitch={0.5, 1.5},
		},
		bite = {
			name = "animals_bite",
			gain={0.4, 0.8},
			fade={0.5, 1.5},
			pitch={0.6, 1.1},
		},
	},
  --on actions
	drops = {
		{name = "animals:carcass_fish_large", chance = 1, min = 1, max = 1,},
	},
	on_rightclick = function(self, clicker, time_from_last_click, tool_capabilities)
		if animals.stun_catch_mob(self, clicker, time_from_last_click, tool_capabilities) then -- attack kidnapper
      animals.fight_or_flight(self, clicker, nil, 1)
    end
	end,
  -- egg
  egg = {
    name = "animals:sarkamos_eggs",
    description = S('Sarkamos Eggs'),
    tiles = {"animals_gundu_eggs.png"},
    stack_max = minimal.stack_max_bulky,
    groups = {snappy = 3, edible = 1, egg = 3},
    drawtype = "normal",
    nodebox = nil,
    _medium = 'nodes_nature:salt_water_source',
    _replace = 'nodes_nature:salt_water_flowing',
  },
  -- spawnegg or live animal
  spawnegg = {
    desc = S("Live Sarkamos"),
    inv_img = "animals_sarkamos_item.png",
    stack = minimal.stack_max_medium/2
  },
}
self_data = animals.register_animal("animals:sarkamos",self_data)
