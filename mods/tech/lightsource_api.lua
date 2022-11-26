----------------------------------------
-- Lightsource API
-- allows creating light sources using fuel, e.g. oil lamps, lanterns, etc.
----------------------------------------

-- Internationalization
local S = tech.S

lightsource_description = {}

function lightsource_description.new(args)
    local ld = {
        lit_name = args.lit_name,
        unlit_name = args.unlit_name,
        fuel_name = args.fuel_name,
        max_fuel = args.max_fuel,
        burn_rate = args.burn_rate, -- seconds
        refill_ratio = args.refill_ratio,
        put_out_by_moisture = args.put_out_by_moisture,
    }
    return ld
end

lightsource = {}

function lightsource.start_burning(desc, pos)
    local meta = minetest.get_meta(pos)
    local fuel = meta:get_int("fuel")
    meta:set_int("fuel", fuel)
    minetest.get_node_timer(pos):start(desc.burn_rate)
end

function lightsource.restore_from_inventory(desc, pos, itemstack)
    local meta = minetest.get_meta(pos)
    local stack_meta = itemstack:get_meta()
    local fuel = stack_meta:get_int("fuel")
    if not fuel then
        meta:set_int("fuel", 0)
    end
    if fuel > 0 then
        meta:set_int("fuel", fuel)
    end
    if itemstack:get_name() == desc.lit_name then
        lightsource.start_burning(desc, pos)
        lightsource.update_fuel_infotext(desc, pos)
    end
end

--convert fuel number to a string
function lightsource.update_fuel_infotext(desc, pos)
    local fuel_string = ""
    local meta = minetest.get_meta(pos)
    local fuel = meta:get_int("fuel")
    if not fuel or fuel < 1 then
        fuel_string = S("Empty")
    else
        fuel_string = math.floor(fuel / desc.max_fuel * 100).."% "..S("fuel left")
    end
    minimal.infotext_merge(pos, S("Status: ")..fuel_string, meta)
end

function lightsource.save_to_inventory(desc, pos, digger, lit)
    if not digger then return false end
    if minetest.is_protected(pos, digger:get_player_name()) then
        return false
    end
    local meta = minetest.get_meta(pos)
    local fuel = meta:get_int("fuel")
    local new_stack
    if lit then
        new_stack = ItemStack(desc.lit_name)
    else
        new_stack = ItemStack(desc.unlit_name)
    end
    local stack_meta = new_stack:get_meta()
    stack_meta:set_int("fuel", fuel)
    minetest.remove_node(pos)
    local player_inv = digger:get_inventory()
    if player_inv:room_for_item("main", new_stack) then
        player_inv:add_item("main", new_stack)
    else
        minetest.add_item(pos, new_stack)
    end
end

local function check_for_moisture(pos)
    return climate.get_rain(pos) or minetest.find_node_near(pos, 1, {"group:water"})
end

local function check_for_air(pos)
    return minetest.find_node_near(pos, 1, {"air"})
end

function lightsource.extinguish(desc, pos)
    minetest.swap_node(pos, {name = desc.unlit_name})
    lightsource.update_fuel_infotext(desc, pos)
    minetest.check_for_falling(pos)
end

-- FIXME: needs to actually spawn particles
function lightsource.spawn_particles(desc, pos)
    -- if math.random() < 0.8 then
    --     minetest.sound_play("tech_fire_small",{pos = pos, max_hear_distance = 10, loop = false, gain = 0.1})
    --     --Smoke
    --     minetest.add_particlespawner(ncrafting.particle_smokesmall(pos))
    -- end
end

-- timer
function lightsource.burn_fuel(desc, pos)
    local meta = minetest.get_meta(pos)
    local fuel = meta:get_int("fuel")
    local has_air = check_for_air(pos)
    local moisture = check_for_moisture(pos)
    lightsource.update_fuel_infotext(desc, pos)
    if fuel < 1 then
       minetest.set_node(pos, {name = desc.unlit_name})
       minetest.check_for_falling(pos)
       return false -- stop timer
    elseif not has_air or moisture and desc.put_out_by_moisture then
       lightsource.extinguish(desc, pos)
       return false -- stop timer
    else
        -- lightsource.spawn_particles(desc, pos)
        meta:set_int("fuel", fuel - math.random(-1, 3))
        return true -- next iteration
    end
end

function lightsource.ignite(desc, pos)
    local meta = minetest.get_meta(pos)
    local fuel = meta:get_int("fuel")
    if fuel and fuel > 0 then
        minimal.switch_node(pos, {name = desc.lit_name})
        minetest.registered_nodes[desc.lit_name].on_construct(pos)
        meta:set_int("fuel", fuel)
    end
    lightsource.update_fuel_infotext(desc, pos)
end

function lightsource.refill(desc, pos, clicker, itemstack)
    --hit it with oil to restore
    local stack_name = itemstack:get_name()
    local meta = minetest.get_meta(pos)
    local fuel = meta:get_int("fuel")
    if stack_name == desc.fuel_name then
        if fuel and fuel < desc.max_fuel then
            fuel = fuel + desc.refill_ratio * desc.max_fuel
            if fuel > desc.max_fuel then fuel = desc.max_fuel end -- yeah, I know lol
            meta:set_int("fuel", fuel)
            local name = clicker:get_player_name()
            if not minetest.is_creative_enabled(name) then
                itemstack:take_item()
            end
            lightsource.update_fuel_infotext(desc, pos)
            return itemstack
        end
    end
end
