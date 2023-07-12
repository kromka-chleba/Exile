local random = math.random

player_api = player_api
creative = creative

local store = minetest.get_mod_storage()
local saved_u_boats = minetest.deserialize(store:get_string("savedab"), true)
   or {}

-- Functions

local function is_water(pos)
	local nn = minetest.get_node(pos).name
	return minetest.get_item_group(nn, "water") ~= 0
end

local function get_sign(i)
	if i == 0 then
		return 0
	else
		return i / math.abs(i)
	end
end

-- u_boat entity

local u_boat = {
		initial_properties = {
		physical = true,
		collide_with_objects = true,
		selectionbox = {-0.9, 0.5, -0.9, 0.9, 1.7, 0.9},
		collisionbox = {-1.2, -2, -1.2, 1.2, 2, 1.2},
		visual = "wielditem",
		visual_size = {x = 2.0, y = 2.0}, -- Scale up of nodebox is these * 1.5
		textures = {"artifacts:u_boat_nodebox"},
	},

	-- Custom fields
	driver = nil,
	removed = false,
	redundant = false,
	v = 0,
	vx = 0,
	vy = 0,
	rot = 0,
	auto = false,
}

function u_boat.attach (self, player, pname)
   local attach = player:get_attach()
   if attach and attach:get_luaentity() then
      local luaentity = attach:get_luaentity()
      if luaentity.driver then
	 luaentity.driver = nil
      end
      player:set_detach()
   end
   self.driver = pname or player:get_name()
   player:set_attach(self.object, "",
		     {x = 0, y = -9, z = -2}, {x = 0, y = 0, z = 0})
   player_api.player_attached[pname] = true
   minetest.after(0.2, function()
		     player_api.set_animation(player, "sit" , 30)
		     player:set_eye_offset(
			{x = 0, y = -12, z = 0},
			{x = 0, y = 0, z = 0})
   end)
   minetest.sound_play("artifacts_airboat_gear",
		       {pos = self.object:get_pos().pos, gain = 1,
			max_hear_distance = 6})
   player:set_look_horizontal(self.object:get_yaw())
end

function u_boat.on_rightclick(self, clicker)
	if not clicker or not clicker:is_player() then
		return
	end
	local name = clicker:get_player_name()
	local pos = clicker:get_pos()
	if self.driver and name == self.driver then
	   local node local height = 0 local tgt = pos
	   
	   -- Detach
	   self.driver = nil
	   self.auto = false
	   clicker:set_detach()
	   player_api.player_attached[name] = false
	   minetest.after(0.2, function()
			     player_api.set_animation(clicker, "stand" , 30)
			     clicker:set_eye_offset({x = 0, y = 0, z = 0},
				{x = 0, y = 0, z = 0})
	   end)
	   minetest.sound_play("artifacts_airboat_gear",
			       {pos = pos, gain = 1, max_hear_distance = 6})
	   minetest.after(0.1, function()
			     clicker:set_pos(pos)
	   end)
	elseif not self.driver then
	   self:attach(clicker, name)
	end
end

function u_boat.on_punch(self, puncher)
	if not puncher or not puncher:is_player() or self.removed then
		return
	end

	local name = puncher:get_player_name()
        local pos = puncher:get_pos()
	if not self.driver then
		-- Move to inventory
		self.removed = true
		local inv = puncher:get_inventory()
		if not (creative and creative.is_enabled_for
				and creative.is_enabled_for(name))
				or not inv:contains_item("main", "artifacts:u_boat") then
			local leftover = inv:add_item("main", "artifacts:u_boat")
			if not leftover:is_empty() then
				minetest.add_item(self.object:get_pos(), leftover)
			end
		end
		minetest.after(0.1, function()
			self.object:remove()
			minetest.sound_play("artifacts_airboat_gear", {pos = pos, gain = 1, max_hear_distance = 6})
		end)
	end
end

local function clonk(pos)
   if random()>0.98 then
      minetest.sound_play("artifacts_airboat_gear", {pos = pos, gain = 0.25, max_hear_distance = 6})
   end
end

local function limit_and_reduce(vec, cap, decay)
   local s = get_sign(vec)
   vec = vec - decay * s
   if s ~= get_sign(vec) then
      vec = 0
   end
   if math.abs(vec) > cap then
      vec = cap * get_sign(vec)
   end
   return vec
end

local steplimit = 0
function u_boat.on_step(self, dtime)
	steplimit = steplimit + dtime
	if not minetest.is_singleplayer and steplimit < 0.4 then
	   return
	end
	steplimit = 0
	if self.redundant == true then
	   if self.driver == nil then
	      self.object:remove()
	   else
	      self.redundant = false
	   end
	   return
	end
	local lyaw = self.object:get_yaw()
	local lvelocity = vector.rotate_around_axis(
	   self.object:get_velocity(),
	   {x=0, y=1, z=0},
	   lyaw * -1)
	local accel = vector.new()
	--Using three digits of precision
	self.v = math.floor(lvelocity.z * 1000) / 1000 -- forward speed
	self.vx = math.floor(lvelocity.x * 1000) / 1000 -- lateral speed
	self.vy = math.floor(lvelocity.y * 1000) / 1000 -- vertical speed
	local pos = self.object:get_pos()


	-- falls except in water
	local below = vector.new(pos.x, pos.y - 0.5, pos.z)	
	local above = vector.new(pos.x, pos.y + 0.5, pos.z)
	local new_acce
	--if is_water(above) then -- water over us
	  -- if self.vy < 0 then 
	    --  new_acce = {x = 0, y = 0.1, z = 0}
	   --else
	     -- new_acce = {x = 0, y = 0.1, z = 0}
	   --end
	if is_water(below) then -- we're on/in the water
	   new_acce = {x = 0, y = 0, z = 0}

	   --if math.abs(self.vy) < 1
	     -- and pos.y - 0.5 > math.floor(pos.y - 0.5) then
	      --pos.y = math.floor(pos.y + 1) - 0.5
	      --self.object:set_pos(pos)
	   --end
	   --self.y = 0
	elseif is_water(pos) then
	new_acce = {x = 0.1*random(), y=0.1*random(), z = 0.1*random()}	
	else -- no water below 
	   local nodedef = minetest.registered_nodes[minetest.get_node(below).name]
	   if (not nodedef) or nodedef.walkable then
	      --beached, stop
	      self.v = 0
	      new_acce = {x = 0, y = 0, z = 0}
	   else
	      --out of water, begin falling
	      new_acce = {x = 0, y = -10, z = 0}
	   end
	end

	


	-- Controls
	if self.driver then

	   local driver_objref = minetest.get_player_by_name(self.driver)
	   if driver_objref then
	      local ctrl = driver_objref:get_player_control()
	      if (ctrl.up and ctrl.down) or (ctrl.left and ctrl.right) then
		 if not self.auto then
		    self.auto = true
		    minetest.sound_play("artifacts_airboat_gear", {pos = pos, gain = 1, max_hear_distance = 6})
		    minetest.chat_send_player(self.driver,
					      "[u_boat] Cruise on")
		 end
	      elseif ctrl.down then
		 self.v = self.v - 0.05
		 if self.auto then
		    self.auto = false
		    minetest.sound_play("artifacts_airboat_gear", {pos = pos, gain = 1, max_hear_distance = 6})
		    minetest.chat_send_player(self.driver,
					      "[u_boat] Cruise off")
		 end
	      elseif ctrl.up or self.auto then
		 self.v = self.v + 0.1
		driver_objref:set_breath(10)
	      end
	      if ctrl.left then
		 if ctrl.aux1 then
		    self.vx = self.vx + -0.1
		 else
		    self.rot = self.rot + 0.002
		 end
		driver_objref:set_breath(10)
		 clonk(pos)
	      elseif ctrl.right then
		 if ctrl.aux1 then
		    self.vx = self.vx + 0.1
		 else
		    self.rot = self.rot - 0.002
		 end
		driver_objref:set_breath(10)
		 clonk(pos)
	      end
	      if ctrl.jump then
		 self.vy = self.vy + 0.03
		driver_objref:set_breath(10)
		 clonk(pos)
	      elseif ctrl.sneak then
		 self.vy = self.vy - 0.03
		driver_objref:set_breath(10)
		 clonk(pos)
	      end
	   else -- has a driver but no driver object, driver has been lost
	      minetest.log("action","An u_boat at "..pos.x.."/"..pos.y.."/"..
			   pos.z.." has lost its driver due to crash or "..
			   "disconnect, removing it.")
	      self:on_detach_child()
	   end
	end

	-- Early return for stationary vehicle
	if self.v == 0 and self.rot == 0 and self.vy == 0 and self.vx == 0 then
		self.object:set_pos(self.object:get_pos())
		return
	end

	-- Reduction and limiting of rotation
	self.rot = limit_and_reduce(self.rot, 0.01, 0.0004)
	-- Reduction and limiting of speed: forward, vertical, lateral
	self.v  = limit_and_reduce(self.v,  2, 0.03)
	self.vy = limit_and_reduce(self.vy, 1, 0.02)
	self.vx = limit_and_reduce(self.vx, 1, 0.02)

	local newvec = vector.subtract(vector.new(self.vx, self.vy, self.v),
				       lvelocity)
	newvec = vector.rotate_around_axis(newvec,
					   { x = 0, y = 1, z = 0 }, lyaw)
	self.object:add_velocity(newvec)
	self.object:set_acceleration(new_acce)
	self.object:set_yaw(lyaw + (1 + dtime) * self.rot)

end


minetest.register_entity("artifacts:u_boat", u_boat)


-- Craftitem

minetest.register_craftitem("artifacts:u_boat", {
	description = "u_boat",
	inventory_image = "artifacts_u_boat_inv.png",
	stack_max = 1,
	wield_scale = {x = 4, y = 4, z = 4},
	liquids_pointable = true,

	on_place = function(itemstack, placer, pointed_thing)
		local under = pointed_thing.under
		local node = minetest.get_node(under)
		local udef = minetest.registered_nodes[node.name]

		-- Run any on_rightclick function of pointed node instead
		--if udef and udef.on_rightclick and
		--		not (placer and placer:is_player() and
		--		placer:get_player_control().sneak) then
		--	return udef.on_rightclick(under, node, placer, itemstack,
		--		pointed_thing) or itemstack
		--end

		if pointed_thing.type ~= "node" then
			return itemstack
		end

		pointed_thing.under.y = pointed_thing.under.y + 1
		local uboat = minetest.add_entity(pointed_thing.under,
			"artifacts:u_boat")
		minetest.sound_play("artifacts_airboat_gear",
				    {pos = pointed_thing.under,
				     gain = 1, max_hear_distance = 6})
		if uboat then
		   if placer then
		      uboat:set_yaw(placer:get_look_horizontal())
		   end
		   local player_name = placer and placer:get_player_name() or ""
		   if not (creative and creative.is_enabled_for and
			   creative.is_enabled_for(player_name)) then
		      itemstack:take_item()
		   end
		end
		return itemstack
	end,
})

function u_boat.on_activate(self, staticdata, dtime_s)
   local mypos = self.object:get_pos()
   if mypos and saved_u_boats then
      mypos = vector.floor(mypos)
      for _, data in pairs(saved_u_boats) do
	 if mypos == vector.floor(data[1]) then
	    self.redundant = true
	 end
      end
   end
   self.object:set_armor_groups({immortal = 1})
end

function u_boat.on_detach_child(self, child)
   if self.driver then -- player was disconnected while inside?
      if child and child:get_hp() == 0 then -- player died, don't save
	 self.driver = nil
	 self.auto = false
	 return
      end
      saved_u_boats[self.driver] = { self.object:get_pos(),
				      self.object:get_yaw() }
      self.object:remove()
      store:set_string("savedab",minetest.serialize(saved_u_boats))
   else
      self.driver = nil
      self.auto = false
   end
end

function u_boat.on_deactivate(self) -- server shutting down??
   if not self.driver then
      return
   end
   saved_u_boats[self.driver] = { self.object:get_pos(),
				   self.object:get_yaw() }
   store:set_string("savedab",minetest.serialize(saved_u_boats))
end


-- Nodebox for entity wielditem visual

minetest.register_node("artifacts:u_boat_nodebox", {
	description = "U-boat Nodebox",
	tiles = { -- Top, base, right, left, front, back
		"artifacts_u_boat_top.png",
		"artifacts_u_boat_base.png",
		"artifacts_u_boat_right.png",
		"artifacts_u_boat_left.png",
		"artifacts_u_boat_front.png",
		"artifacts_u_boat_back.png",
	},
	paramtype = "light",
	light_source = 20,
	drawtype = "nodebox",
	node_box = {
	type = "fixed",
	fixed = {
		{-0.2500, -0.2500, -0.5000, 0.2500, -0.1875, 0.5000},
		{-0.2500, 0.1875, -0.5000, 0.2500, 0.2500, 0.5000},
		{-0.2500, -0.2500, -0.5000, -0.1875, 0.2500, 0.5000},
		{0.1875, -0.2500, -0.5000, 0.2500, 0.2500, 0.5000},
		{-0.2500, -0.2500, -0.5000, 0.2500, 0.2500, -0.5000}
	}
	},
	groups = {not_in_creative_inventory = 1},
})

minetest.register_on_joinplayer(function(player)
      local plname = player:get_player_name()
      if saved_u_boats and saved_u_boats[plname] then
	 local pos = saved_u_boats[plname][1]
	 local yaw = saved_u_boats[plname][2]
	 local uboat = minetest.add_entity(pos,
					      "artifacts:u_boat")
	 if uboat then
	       uboat:set_yaw(yaw)
	       local ab = uboat:get_luaentity()
	       ab:attach(player, plname)
	 end
	 minetest.after(5, function()
			   saved_u_boats[plname] = nil
			   store:set_string("savedab",
					    minetest.serialize(saved_u_boats))
	 end)
      end
end)
