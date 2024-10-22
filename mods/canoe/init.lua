-- canoe/init.lua

-- Internationalization
local S = minetest.get_translator("canoe")

--
-- Helper functions
--
local random = math.random

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


--
-- canoe entity
--

local canoe = {
    _desc = S("Canoe"),
    initial_properties = {
        physical = true,
        -- Warning: Do not change the position of the collisionbox top surface,
        -- lowering it causes the canoe to fall through the world if underwater
        collisionbox = {-0.5, -0.35, -0.5, 0.5, 0.3, 0.5},
        visual = "mesh",
        mesh = "canoe_canoe.obj",
        textures = {"canoe_texture.png"},

    },

    driver = nil,
    v = 0,
    last_v = 0,
    removed = false,
}



function canoe.on_rightclick(self, clicker)
    if not clicker or not clicker:is_player() then
        return
    end

    local name = clicker:get_player_name()
    --get off canoe
    if self.driver and name == self.driver then
        self.driver = nil
        clicker:set_detach()
        player_api.player_attached[name] = false
        player_api.set_animation(clicker, "stand" , 30)
        local pos = clicker:get_pos()
        pos = {x = pos.x, y = pos.y + 0.2, z = pos.z}
        minetest.after(0.1, function()
                           clicker:set_pos(pos)
        end)
        --get on canoe
    elseif not self.driver then
        local attach = clicker:get_attach()
        if attach and attach:get_luaentity() then
            local luaentity = attach:get_luaentity()
            if luaentity.driver then
                luaentity.driver = nil
            end
            clicker:set_detach()
        end
        self.driver = name
        clicker:set_attach(self.object, "",
                           {x = 0.5, y = 1, z = -3}, {x = 0, y = 0, z = 0})
        player_api.player_attached[name] = true
        minetest.after(0.2, function()
                           player_api.set_animation(clicker, "sit" , 30)
        end)
        clicker:set_look_horizontal(self.object:get_yaw())
    end
end


-- If driver leaves server while driving canoe
function canoe.on_detach_child(self, child)
    self.driver = nil
end


function canoe.on_activate(self, staticdata, dtime_s)
    self.object:set_armor_groups({immortal = 1})
    if staticdata then
        self.v = tonumber(staticdata)
    end
    self.last_v = self.v
end


function canoe.get_staticdata(self)
    return tostring(self.v)
end

-- wobbling animation
-- "anim" is transferred via minetest.after
local function canoe_anim(self, anim)
    -- create anim table if does not exist
    -- phase, num, and rot (rotation)
    anim = anim or {phase=1,num=0,rot=self.object:get_rotation()}
    -- num is how many iterations, keys in the pseudo-animation
    anim.num = anim.num + 1
    -- max is either 5 or 10 (for initial, swing back, and ending) depending on animation phase
    -- phase 2 and 3 are for swinging back from right and left
    -- when max is hit, reset num, go to next phase
    if (anim.phase == 1 or anim.phase == 4) and anim.num >= 5 or anim.num >= 10 then
        anim.phase = anim.phase + 1
        anim.num = 0
    end
    -- end of pseudo-animation, reset z coordinate and then return
    if anim.phase > 4 then
        anim.rot.z = 0
        self.object:set_rotation(anim.rot)
        self.is_hit_anim = nil -- permit more hit animations
        return
    end
    local z = anim.rot.z
    local amt = math.pi*0.012 -- amount: how much to change rotation by per iteration
    amt = anim.phase%2 == 0 and -amt or amt -- even numbered phases are going left
    anim.rot.z = z + amt -- change z coordinate by amount
    self.object:set_rotation(anim.rot)
    minetest.after(0.01,canoe_anim,self,anim) -- run function with parameters self and anim
end

-- check if the wobble pseudo-animation is playing, return if so
-- play the wobble pseudo-animation if it's not playing :D 
local function check_and_play_canoe_anim(self)
    if self.is_hit_anim then return end
    self.is_hit_anim = true -- we're playing the animation, prevent it from playing again while it runs
    canoe_anim(self) -- play pseudo-animation
end

--!!change this for keeping an inventory in canoe ? no picking up canoe?
function canoe.on_punch(self, puncher, time_from_last_punch,
    tool_capabilities, dir)
    if self.removed or not puncher then -- if we're being removed already or puncher doesn't even exist!
        return
    end
    if type(puncher) ~= "userdata" and type(puncher) ~= "table" then return end -- not an entity of any sort
    self.hp = self.hp or self.object:get_hp() -- set hp if not set
    local is_player = minetest.is_player(puncher)

    -- get name and check if in creative
    local name = is_player and puncher:get_player_name()
    local in_creative = is_player and minimal.player_in_creative(puncher)

    -- play a pseudo-animation for being hit
    check_and_play_canoe_anim(self)

    -- if player and either: puncher is the driver or no driver
    -- then increase pickup_progress
    if is_player and ((self.driver and name == self.driver) or not self.driver) then
        self.pickup_progress = self.pickup_progress and self.pickup_progress + 1 or 1
    -- else, this boat is gon sink!
    else
        self.pickup_progress = nil
        -- damage
        local dmg = tool_capabilities and tool_capabilities.damage_groups
        -- do "woody" damage or fleshy divided by 3
        dmg = dmg and (dmg.woody or (dmg.fleshy/3)) or 1
        local fpi = tool_capabilities and tool_capabilities.full_punch_interval or 1
        -- get damage percentage from time_from_last_punch (or fpi if not provied) divided by fpi, clamp to fpi if over
        -- times harm by it
        dmg = in_creative and dmg or dmg * math.min((time_from_last_punch or fpi) / fpi, fpi)
        -- only harm canoe if damage is over 0.25
        if dmg > 0.25 then
            self.hp = self.hp - dmg
        end
    end
    -- if we're the driver and punching, then eject! or if the ship's going down, eject the driver!
    if self.driver and (self.hp <= 0 or name == self.driver) then
        -- if it's player ejecting, then set to puncher
        -- if it's the driver being injected by a sinking canoe, then eject the driver
        -- ensure it's set to a separate driver variable
        local driver = name == self.driver and puncher or
            self.hp <= 0 and (self.driver and minetest.get_player_by_name(self.driver)) or nil
        -- ensure the driver PROPERLY detaches
        if driver then
            driver:set_detach()
            player_api.player_attached[driver:get_player_name()] = false
        end
        self.driver = nil
    end
    -- now for what to do when we've finally picked up the boat... or destroyed it!
    if self.hp <= 0 or (self.pickup_progress and self.pickup_progress > 3) then
        self.removed = true
        -- we're being picked up (self.pickup_progress > 3)
        if self.hp > 0 and is_player then
            local inv = puncher:get_inventory()
            -- if not in creative or in creative but there is no canoe in inventory
            if not in_creative
                or not inv:contains_item("main", "canoe:canoe") then
                local leftover = inv:add_item("main", "canoe:canoe")
                -- if no room in inventory add a replacement canoe to the world
                if not leftover:is_empty() then
                    minetest.add_item(self.object:get_pos(), leftover)
                end
            end
        -- we're being actively destroyed, drop as an item!
        else
            minetest.add_item(self.object:get_pos(), ItemStack("canoe:canoe"))
        end
        -- delay remove to ensure player is detached
        minetest.after(0.1,function()
            self.object:remove()
        end)
    end
    
    --[[
    if not self.driver then
        --self.removed = true
        local inv = puncher:get_inventory()
        if not minimal.player_in_creative(puncher)
            or not inv:contains_item("main", "canoe:canoe") then
            minetest.log("boap")
            local leftover = inv:add_item("main", "canoe:canoe")
            -- if no room in inventory add a replacement canoe to the world
            if not leftover:is_empty() then
                minetest.add_item(self.object:get_pos(), leftover)
            end
        end
        -- delay remove to ensure player is detached
        --minetest.after(0.1, function()
                           --self.object:remove()
        --end)
    end
    --]]
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
function canoe.on_step(self, dtime)
    steplimit = steplimit + dtime
    if not minetest.is_singleplayer()
        and steplimit < 0.2 then
        return
    end
    dtime = steplimit
    steplimit = 0
    local lyaw = self.object:get_yaw()
    local lvelocity = vector.rotate_around_axis(
        self.object:get_velocity(),
        {x=0, y=1, z=0},
        lyaw * -1)
    local pos = self.object:get_pos()
    --Using three digits of precision
    self.v = math.floor(lvelocity.z * 1000) / 1000 -- forward speed
    self.y = math.floor(lvelocity.y * 1000) / 1000 -- vertical speed
    --paddle canoe
    if self.driver then
        local driver_objref = minetest.get_player_by_name(self.driver)
        if driver_objref then
            local ctrl = driver_objref:get_player_control()
            if ctrl.down then
                self.v = self.v - dtime * 1.8
                if random()>0.9 then
                    minetest.sound_play("nodes_nature_water_footstep",
                                        {pos = pos, gain = random(0.1,0.3),
                                         max_hear_distance = 6})
                end
            elseif ctrl.up then
                self.v = self.v + dtime * 1.5
                if random()>0.9 then
                    minetest.sound_play("nodes_nature_water_footstep",
                                        {pos = pos, gain = random(0.1,0.3),
                                         max_hear_distance = 6})
                end
            end
            if ctrl.left then
                if random()>0.9 then
                    minetest.sound_play("nodes_nature_water_footstep",
                                        {pos = pos, gain = random(0.1,0.3),
                                         max_hear_distance = 6})
                end
                if self.v < -0.001 then
                    self.object:set_yaw(self.object:get_yaw() - dtime * 0.9)
                else
                    self.object:set_yaw(self.object:get_yaw() + dtime * 0.9)
                end
            elseif ctrl.right then
                if self.v < -0.001 then
                    self.object:set_yaw(self.object:get_yaw() + dtime * 0.9)
                else
                    self.object:set_yaw(self.object:get_yaw() - dtime * 0.9)
                end
            end
        end
    end

    self.v = limit_and_reduce(self.v, 5, dtime * 0.3)
    --self.v = self.v - dtime * 0.6 * s

    --early return if motionless
    if self.v == 0 and lvelocity.x == 0
        and lvelocity.y == 0 and lvelocity.x == 0 then
        return
    end

    local below = vector.new(pos.x, pos.y - 0.5, pos.z)
    local above = vector.new(pos.x, pos.y + 0.5, pos.z)
    local new_acce
    if is_water(above) then -- water over us
        if self.y < 0 then -- rise hard if falling
            new_acce = {x = 0, y = 10, z = 0}
        else
            new_acce = {x = 0, y = 4, z = 0}
        end
    elseif is_water(below) then -- we're on the surface
        new_acce = {x = 0, y = 0, z = 0}

        if math.abs(self.y) < 1
            and pos.y - 0.5 > math.floor(pos.y - 0.5) then
            pos.y = math.floor(pos.y + 1) - 0.5
            self.object:set_pos(pos)
        end
        self.y = 0
    else -- no water below either
        local nodedef = minetest.registered_nodes[minetest.get_node(below).name]
        if (not nodedef) or nodedef.walkable then
            --beached, stop
            self.v = 0
            new_acce = {x = 0, y = 0, z = 0}
        else
            --out of water, begin falling
            new_acce = {x = 0, y = -9.8, z = 0}
        end
    end

    local new_velo = vector.subtract(
        vector.new(0, self.y, self.v),
        lvelocity)
    new_velo = vector.rotate_around_axis(
        new_velo,
        { x = 0, y = 1, z = 0},
        lyaw)
    self.object:add_velocity(new_velo)
    self.object:set_acceleration(new_acce)
end


minetest.register_entity("canoe:canoe", canoe)


local canoe_def = {
    description = S("Dugout Canoe"),
    inventory_image = "canoe.png",
    wield_image = "canoe.png",
    wield_scale = {x = 3, y = 3, z = 1},
    liquids_pointable = true,
    groups = {flammable = 1},
    stack_max = 1,

    on_place = function(itemstack, placer, pointed_thing)
        local under = pointed_thing.under
        local node = minetest.get_node(under)
        local udef = minetest.registered_nodes[node.name]

        if pointed_thing.type ~= "node" then
            return itemstack
        end
        if not is_water(pointed_thing.under) then
            return itemstack
        end
        pointed_thing.under.y = pointed_thing.under.y + 0.5
        canoe = minetest.add_entity(pointed_thing.under, "canoe:canoe")
        if canoe then
            if placer then
                canoe:set_yaw(placer:get_look_horizontal())
            end
            if not (minimal.player_in_creative(placer)) then
                itemstack:take_item()
            end
        end
        return itemstack
    end,
}
minetest.register_craftitem("canoe:canoe", canoe_def)


--
--recipe
--
crafting.register_recipe({
        type = {"chopping_block","axe"},
        output = "canoe:canoe",
        items = {"group:log 6"},
        level = 1,
        always_known = true,
})
