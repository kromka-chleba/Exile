-- torch.lua

-- Internationalization
local S = tech.S

local c_alpha = EXILE.compat_alpha

--interval
local base_burn_rate = 6
--how much to burn
local base_fuel = 60
--brightness
local light_power = 8
local temp = 2
local heat = 450




-------------------------------------------
--save usage into inventory, to prevent infinite torch supply
local on_dig = function(pos, node, digger)
    if not core.is_player(digger) then return end

    local meta = minetest.get_meta(pos)
    if minetest.is_protected(pos, digger, meta) then
        return false
    end

    local fuel = meta:get_int("fuel")
    --round off fuel numbers for better stacking: 10-15 = 10
    --16-20 = 20, lean a bit towards reducing fuel for balance
    fuel = math.floor((fuel+4)/10)*10

    local new_stack = ItemStack("tech:torch")
    local stack_meta = new_stack:get_meta()
    stack_meta:set_int("fuel", fuel)

    EXILE.protection_on_dig(pos, node, digger, meta)

    local player_inv = digger:get_inventory()
    if player_inv:room_for_item("main", new_stack) then
        player_inv:add_item("main", new_stack)
        minetest.remove_node(pos)
    elseif not EXILE.stop_on_inv_full(digger) then
        minetest.add_item(pos, new_stack)
        minetest.remove_node(pos)
    end
end


-------------------------------------------
-- set saved fuel

-- not used by thrown torches

local after_place_node = function(pos, _placer, itemstack, _pt, nmeta, imeta)
    nmeta = nmeta or core.get_meta(pos)
    imeta = imeta or itemstack:get_meta()
    --[[if item placed had a "fuel" meta value,
    --  then override node's one by this one ]]
    --[[#TODO question: should we delete that in on_construct
    -- and only put it-- here ? Else, the "or base_fuel" seems useless
    -- because done on on_construct which is called before after_place_node.]]--
    local fuel = tonumber(imeta:get("fuel")) or base_fuel
    nmeta:set_int("fuel", fuel)
end

-------------------------------------------
--drop dead torch. Fuel used up or damaged somehow.
local function drop_dead_torch(pos)
    minetest.add_item(pos, ItemStack('tech:stick'))
    minetest.set_node(pos, {name = 'air'})
end

-------------------------------------------
--converts flaming torch into a dead torch
local function can_burn_air(pos)
    --extinguish
    if climate.get_rain(pos)
    or minetest.find_node_near(pos, 1, {"group:water"}) then
        drop_dead_torch(pos)
        return false
    end

    --check for the presence of air
    if minetest.find_node_near(pos, 1, {"air"}) then
        return true
    else
        --go out
        drop_dead_torch(pos)
        return false
    end
end

--Particle Effects
local function torch_fire_on(pos)
    if math.random()<0.8 then
        minetest.sound_play("tech_fire_small",
                            {pos=pos, max_hear_distance = 10,
                             loop=false, gain=0.1})
        --Smoke
        minetest.add_particlespawner(ncrafting.particle_smokesmall(pos))
    end
end

-------------------------------------------
--handles dropping the torch

local function on_throw(itemstack, dropper, pos)
    -- newpos = {x = pos.x, y = pos.y+1.5, z=pos.z} -- Add vector to put it forward
    local obj = minetest.add_entity({x = pos.x, y = pos.y+1.5, z = pos.z},
        "tech:torch_entity")
    --fuel of thrown torch is current fuel, or base_fuel if new torch
    local fuel = tonumber(itemstack:get_meta():get("fuel")) or base_fuel
    obj:get_luaentity(obj):set_fuel(fuel)

    local vectors = dropper:get_look_dir()
    local velocity = 10
    obj:set_velocity({x = vectors.x * velocity,
                      y = vectors.y * velocity,
                      z = vectors.z * velocity})
    obj:set_acceleration({ x = vectors.x * -5, y = -10, z = vectors.z * -5})
end


local torch_entity = {
    initial_properties = {
        visual = "sprite",
        textures = {"tech_torch_on_floor.png"},
        physical = true,
        collisionbox = {-0.125, 0.0, -0.125, 0.125, .25, 0.125}
    },
    fuel = 60 -- default to a new torch
}
function torch_entity:on_step(_dtime, _moveresult)
    local vel = self.object:get_velocity()
    if vel.y == 0 then

        local pos = self.object:get_pos()
        local here = minetest.get_node(pos)
        local def = minetest.registered_nodes[here.name]
        if not here.name then -- we're in an unloaded spot, just forget it
            self.remove()
            return
        end
        if def.groups.water and def.groups.water > 0 then
            minetest.sound_play("nodes_nature_cool_lava",
                                {pos = pos, max_hear_distance = 16, gain = 0.1})
        elseif def.groups.igniter and def.groups.igniter > 0 then
            minetest.sound_play("inferno_extinguish_flame.2",
                                {pos = pos, max_hear_distance = 16, gain = 0.1})
        elseif not def.buildable_to then
            local torchent = ItemStack("tech:torch")
            torchent:get_meta():set_int("fuel", self.fuel)
            minetest.item_drop(torchent, nil, pos)
        else
            minetest.place_node(pos, {name = "tech:torch"})
            local heremeta = minetest.get_meta(pos)
            heremeta:set_int("fuel", self.fuel)
        end
        self.object:remove()
    end
end
function torch_entity:get_fuel()
    return self.fuel
end
function torch_entity:set_fuel(val)
    self.fuel = val
end

minetest.register_entity("tech:torch_entity", torch_entity)

-------------------------------------------

local function on_flood(pos, _oldnode, _newnode)
    drop_dead_torch(pos)
    --minetest.add_item(pos, ItemStack("tech:torch 1"))
    -- Play flame-extinguish sound if liquid is not an 'igniter'
    --[[
        local nodedef = minetest.registered_items[newnode.name]
        if not (nodedef and nodedef.groups and
        nodedef.groups.igniter and nodedef.groups.igniter > 0) then
        minetest.sound_play(
        "default_cool_lava",
        {pos = pos, max_hear_distance = 16, gain = 0.1}
        )
        end
    ]]
    -- Remove the torch node
    return false
end


-------------------------------------------
-- Register torches (common def)
local function register_torch_node (name, given_def)
    local def = {
        drawtype = "mesh",
        tiles = {{
            name = "tech_torch_on_floor_animated.png",
            animation = {type = "vertical_frames",
                         aspect_w = 16, aspect_h = 16,
                         length = 3.3}
                     }},

        use_texture_alpha = c_alpha.clip,
        paramtype = "light",
        paramtype2 = "wallmounted",
        sunlight_propagates = true,
        walkable = false,
        light_source = light_power,
        temp_effect = temp,
        temp_effect_max = heat,

        groups = {
            choppy=2,
            dig_immediate=3,
            attached_node=1,
            torch=1,
            temp_effect = 1,
            temp_pass = 1
        },

        drop = "tech:torch",

        sounds = nodes_nature.node_sound_wood_defaults(),
        floodable = true,
        on_flood = on_flood,
        on_dig = on_dig,

        on_construct = function(pos)
            --duration of burn
            local meta = minetest.get_meta(pos)
            meta:set_int("fuel", base_fuel)
            --fire effects..
            minetest.get_node_timer(pos):start(
                math.random(base_burn_rate-1,base_burn_rate+1))
        end,

        after_place_node = after_place_node,

        on_timer =function(pos, _elapsed)
            local meta = minetest.get_meta(pos)
            local fuel = meta:get_int("fuel")
            if fuel < 1 then
                drop_dead_torch(pos)
                return false
            elseif can_burn_air(pos) then
                torch_fire_on(pos)
                meta:set_int("fuel", fuel - 1)
                -- Restart timer
                return true
            end
        end,
    }

    -- complete/override def fields with given_def values and groups
    for field, value in pairs(given_def) do
        if field ~= "groups" then
            def[field] = value
        else -- groups field, add them
            for g,v in pairs(def.groups) do
                def.groups[g] = v
            end
        end
    end

    core.register_node(name, def)
end

-- base item + floor torch definition
register_torch_node("tech:torch", {
    mesh = "torch_floor.obj",
    selection_box = {
        type = "wallmounted",
        wall_bottom = {-1/8, -1/2, -1/8, 1/8, 2/16, 1/8},
    },

    description = S("Torch"),
    inventory_image = "tech_torch_on_floor.png",
    wield_image = "tech_torch_on_floor.png",
    stack_max = EXILE.stack_max_medium,
    liquids_pointable = false,

    on_drop = function(itemstack, dropper, pos)
        on_throw(itemstack, dropper, pos)
        if not EXILE.player_in_creative(dropper) then
            itemstack:take_item()
            return itemstack
        end
    end,

    on_place = function(itemstack, placer, pointed_thing)
        local under = pointed_thing.under
        local above = pointed_thing.above

        if EXILE.pos_group(above, "water") then
            on_throw(itemstack, placer, pointed_thing.under)
            if not EXILE.player_in_creative(placer) then
                itemstack:take_item(1)
            end
            return itemstack
        end
        if ( minetest.is_player(placer)
             and not placer:get_player_control().sneak) then
            local on_click = EXILE.on_rightclick(itemstack, placer,
                                                   pointed_thing)
            if on_click ~= false then
                return on_click or itemstack
            end
        end
        local wdir = minetest.dir_to_wallmounted(
            vector.subtract(under, above))
        local fakestack = itemstack
        if wdir == 0 then
            fakestack:set_name("tech:torch_ceiling")
        elseif wdir == 1 then
            fakestack:set_name("tech:torch")
        else
            fakestack:set_name("tech:torch_wall")
        end

        itemstack = minetest.item_place(
            fakestack, placer, pointed_thing, wdir)
        itemstack:set_name("tech:torch")

        return itemstack
    end,
})

-- torch on a wall
register_torch_node("tech:torch_wall", {
    mesh = "torch_wall.obj",
    selection_box = {
        type = "wallmounted",
        wall_side = {-1/2, -1/2, -1/8, -1/8, 1/8, 1/8},
    },
    groups = {not_in_creative_inventory = 1}
})

-- torch under a ceiling
register_torch_node("tech:torch_ceiling", {
    mesh = "torch_ceiling.obj",
    selection_box = {
        type = "wallmounted",
        wall_top = {-1/8, -1/16, -5/16, 1/8, 1/2, 1/8},
    },
    groups = {not_in_creative_inventory = 1},
})


------------------------------------------
--Recipe
--
--Hand crafts (inv)
--

--A bundle from sticks and fibre
crafting.register_recipe({
        type = {"crafting_spot",'knife','hand'},
        output = "tech:torch 1",
        items = {"tech:stick 1", "group:fibrous_plant 4"},
        level = 0,
        always_known = true,
})
