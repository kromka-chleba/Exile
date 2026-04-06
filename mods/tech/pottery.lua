------------------------------------------------
-- POTTERY
-- all made from clay
--unfired versions must reach right temperature for long enough to fire.
-----------------------------------------------

-- Internationalization
local S = tech.S

local c_alpha = EXILE.compat_alpha

--firing difficulty
local base_firing = ncrafting.base_firing
local firing_int = ncrafting.firing_int
local sediment = nodes_nature.sediment
lightsource = lightsource
lightsource_description = lightsource_description

---
--Broken Pottery
--if you smash it up, or from failed firings
local ruined_pottery_timer = 12000 -- 10 Exile days
--slab
minetest.register_node(
    "tech:ruined_pottery_slab", {
        description = S("Broken Pottery Slab"),
        tiles = {"tech_ruined_pottery.png"},
        stack_max = EXILE.stack_max_bulky *2,
        paramtype = "light",
        drawtype = "nodebox",
        node_box = {
            type = "fixed",
            fixed = {-0.5, -0.5, -0.5, 0.5, 0, 0.5},
        },
        groups = {cracky = 3, falling_node = 1, oddly_breakable_by_hand = 3},
        sounds = nodes_nature.node_sound_gravel_defaults(),
        _use_tip = S("Combine with another slab"),
        _combines_by_hand = "tech:ruined_pottery",
        _on_use_item = function(player, wielded_item, pointed_thing)
            return EXILE.slabs_combine(player, wielded_item,
              EXILE.get_usable_position(pointed_thing))
        end,
        on_construct = function(pos)
            minetest.get_node_timer(pos):start(ruined_pottery_timer/2)
        end,
        on_timer = function(pos,_elapsed)
            minetest.set_node(pos,{name = "stairs:slab_clay"})
        end,
})

-- Broken pottery full block
minetest.register_node(
    "tech:ruined_pottery",{
        description = S("Broken Pottery"),
        groups = {falling_node = 1, crumbly = sediment.hardness.soft},
        sounds =  nodes_nature.node_sound_gravel_defaults(),
        tiles = {"tech_ruined_pottery.png"},
        stack_max = EXILE.stack_max_bulky,
        on_construct = function(pos)
            minetest.get_node_timer(pos):start(ruined_pottery_timer)
        end,
        on_timer = function(pos,_elapsed)
            minetest.set_node(pos,{name = "nodes_nature:clay"})
        end,
})
-- #TODO remove lbm after v4 release
-- replace legacy ruined pottery sediment registration
minetest.register_lbm({
        label = "Update ruined pottery",
        name = "tech:legacy_ruined_pottery_replace",
        nodenames = {
            "tech:slope_ruined_pottery",
            "tech:slope_inner_ruined_pottery",
            "tech:slope_outer_ruined_pottery",
            "tech:slope_pike_ruined_pottery",
            "tech:slope_ruined_pottery_wet",
            "tech:slope_inner_ruined_pottery_wet",
            "tech:slope_outer_ruined_pottery_wet",
            "tech:slope_pike_ruined_pottery_wet",
            "tech:ruined_pottery_wet",
            "tech:ruined_pottery_wet_salty",
            "tech:slope_ruined_pottery_wet_salty",
            "tech:slope_inner_ruined_pottery_wet_salty",
            "tech:slope_outer_ruined_pottery_wet_salty",
            "tech:slope_pike_ruined_pottery_wet_salty"
        },
        action = function(pos, _node, _dtime_s)
            minetest.set_node(pos,{name = "tech:ruined_pottery"})
        end
})

--unfired
minetest.register_node(
    "tech:clay_water_pot_unfired", {
        description = S("Clay Water Pot (unfired)"),
        tiles = {
            "nodes_nature_clay.png",
            "nodes_nature_clay.png",
            "nodes_nature_clay.png",
            "nodes_nature_clay.png",
            "nodes_nature_clay.png",
            "nodes_nature_clay.png"
        },
        drawtype = "nodebox",
        stack_max = EXILE.stack_max_bulky,
        paramtype = "light",
        node_box = {
            type = "fixed",
            fixed = {
                {-0.25, 0.375, -0.25, 0.25, 0.5, 0.25}, -- NodeBox1
                {-0.375, -0.25, -0.375, 0.375, 0.3125, 0.375}, -- NodeBox2
                {-0.3125, -0.375, -0.3125, 0.3125, -0.25, 0.3125}, -- NodeBox3
                {-0.25, -0.5, -0.25, 0.25, -0.375, 0.25}, -- NodeBox4
                {-0.3125, 0.3125, -0.3125, 0.3125, 0.375, 0.3125}, -- NodeBox5
            }
        },
        groups = {dig_immediate=3, temp_pass = 1, heatable = 20,
                  timer = firing_int },
        sounds = nodes_nature.node_sound_stone_defaults(),
        on_construct = function(pos)
            --length(i.e. difficulty of firing), interval for checks (speed)
            ncrafting.set_firing(pos, base_firing, firing_int)
        end,
        on_dig = function(pos, node, digger)
            return ncrafting.on_dig_pottery(pos, node, digger, base_firing)
        end,
        on_timer = function(pos, _elapsed)
            --finished product, length
            return ncrafting.fire_pottery(pos,
                                          "tech:clay_water_pot_unfired",
                                          "tech:clay_water_pot", base_firing)
        end,
})


--------------------------------------
--unfired storage pot (see storage for fired version)
minetest.register_node(
    "tech:clay_storage_pot_unfired", {
        description = S("Clay Storage Pot (unfired)"),
        tiles = {
            "nodes_nature_clay.png",
            "nodes_nature_clay.png",
            "nodes_nature_clay.png",
            "nodes_nature_clay.png",
            "nodes_nature_clay.png",
            "nodes_nature_clay.png"
        },
        drawtype = "nodebox",
        stack_max = EXILE.stack_max_bulky,
        paramtype = "light",
        node_box = {
            type = "fixed",
            fixed = {
                {-0.375, -0.5, -0.375, 0.375, -0.375, 0.375},
                {-0.375, 0.375, -0.375, 0.375, 0.5, 0.375},
                {-0.4375, -0.375, -0.4375, 0.4375, -0.25, 0.4375},
                {-0.4375, 0.25, -0.4375, 0.4375, 0.375, 0.4375},
                {-0.5, -0.25, -0.5, 0.5, 0.25, 0.5},
            }
        },
        groups = {dig_immediate=3, temp_pass = 1, heatable = 20, craftedby = 1,
                  timer = firing_int},
        sounds = nodes_nature.node_sound_stone_defaults(),
        on_construct = function(pos)
            --length(i.e. difficulty of firing), interval for checks (speed)
            ncrafting.set_firing(pos, base_firing+5, firing_int)
        end,
        on_dig = function(pos, node, digger)
            return ncrafting.on_dig_pottery(pos, node, digger, base_firing*5)
        end,
        on_timer = function(pos, _elapsed)
            --finished product, length
            return ncrafting.fire_pottery(pos,
                                          "tech:clay_storage_pot_unfired",
                                          "tech:clay_storage_pot", base_firing+5)
        end,
})

--------------------------------------
--OIL LAMP

--unfired oil clay lamp
minetest.register_node(
    "tech:clay_oil_lamp_unfired", {
        description = S("Clay Oil Lamps (x4) (unfired)"),
        tiles = {
            "nodes_nature_clay.png",
            "nodes_nature_clay.png",
            "nodes_nature_clay.png",
            "nodes_nature_clay.png",
            "nodes_nature_clay.png",
            "nodes_nature_clay.png"
        },
        drawtype = "nodebox",
        stack_max = EXILE.stack_max_medium,
        paramtype = "light",
        paramtype2 = "facedir",
        use_texture_alpha = c_alpha.clip,
        node_box = {
            type = "fixed",
            fixed = {
                --{-0.0625, -0.125, 0.25, 0.0625, 0.0625, 0.4375}, -- flame
                --{-0.125, -0.5, -0.125, 0.125, -0.4375, 0.125}, -- bottom (X: 0.25, Y: 0.0625, Z: 0.25)
                --{-0.0625, -0.4375, -0.0625, 0.0625, -0.3125, 0.0625}, -- stand (X: 0.125, Y: 0.125, Z: 0.125)
                --{-0.125, -0.3125, -0.125, 0.125, -0.125, 0.125}, -- body (X: 0.25, Y: 0.1875, Z: 0.25)
                --{-0.0625, -0.25, 0.125, 0.0625, -0.125, 0.25}, -- spout (X: 0.125, Y: 0.125, Z: 0.125)
                --{-0.0625, -0.1875, -0.1875, 0.0625, -0.125, -0.125}, -- handle (X: 0.125, Y: 0.0625, Z: 0.0625)
                --{-0.0625, -0.3125, -0.1875, 0.0625, -0.25, -0.125}, -- handle (X: 0.125, Y: 0.0625, Z: 0.0625)
                --{-0.0625, -0.3125, -0.25, 0.0625, -0.125, -0.1875}, -- handle (X: 0.125, Y: 0.1875, Z: 0.0625)
                -- total X length: 0.25
                -- total Z length from spout to handles: 0.5625
                -- total Y length from bottom to body: 0.375
                -- 1
                {-0.5, -0.5, -0.375, -0.25, -0.4375, -0.125}, -- bottom
                {-0.4375, -0.4375, -0.3125, -0.3125, -0.3125, -0.1875}, -- stand
                {-0.5, -0.3125, -0.375, -0.25, -0.125, -0.125}, -- body
                {-0.4375, -0.25, -0.5, -0.3125, -0.125, -0.375}, -- spout
                {-0.4375, -0.1875, -0.125, -0.3125, -0.125, -0.0625}, -- handle
                {-0.4375, -0.3125, -0.125, -0.3125, -0.25, -0.0625}, -- handle
                {-0.4375, -0.3125, -0.0625, -0.3125, -0.125, 0}, -- back handle
                -- 2
                {-0.25, -0.5, 0.125, 0, -0.4375, 0.375}, -- bottom
                {-0.1875, -0.4375, 0.3125, -0.0625, -0.3125, 0.1875}, -- stand
                {-0.25, -0.3125, 0.125, 0, -0.125, 0.375}, -- body
                {-0.1875, -0.25, 0.375, -0.0625, -0.125, 0.5}, -- spout
                {-0.1875, -0.1875, 0.0625, -0.0625, -0.125, 0.125}, -- handle
                {-0.1875, -0.3125, 0.0625, -0.0625, -0.25, 0.125}, -- handle
                {-0.1875, -0.3125, 0, -0.0625, -0.125, 0.0625}, -- back handle
                -- 3
                {0, -0.5, -0.375, 0.25, -0.4375, -0.125}, -- bottom
                {0.0625, -0.4375, -0.3125, 0.1875, -0.3125, -0.1875}, -- stand
                {0, -0.3125, -0.375, 0.25, -0.125, -0.125}, -- body
                {0.0625, -0.25, -0.5, 0.1875, -0.125, -0.375}, -- spout
                {0.0625, -0.1875, -0.125, 0.1875, -0.125, -0.0625}, -- handle
                {0.0625, -0.3125, -0.125, 0.1875, -0.25, -0.0625}, -- handle
                {0.0625, -0.3125, -0.0625, 0.1875, -0.125, 0}, -- back handle
                -- 4
                {0.25, -0.5, 0.125, 0.5, -0.4375, 0.375}, -- bottom
                {0.3125, -0.4375, 0.3125, 0.4375, -0.3125, 0.1875}, -- stand
                {0.25, -0.3125, 0.125, 0.5, -0.125, 0.375}, -- body
                {0.3125, -0.25, 0.375, 0.4375, -0.125, 0.5}, -- spout
                {0.3125, -0.1875, 0.0625, 0.4375, -0.125, 0.125}, -- handle
                {0.3125, -0.3125, 0.0625, 0.4375, -0.25, 0.125}, -- handle
                {0.3125, -0.3125, 0, 0.4375, -0.125, 0.0625}, -- back handle
            }
        },
        groups = {dig_immediate=3, temp_pass = 1, falling_node = 1,
                  heatable = 20, timer = firing_int },
        sounds = nodes_nature.node_sound_stone_defaults(),
        on_construct = function(pos)
            --length(i.e. difficulty of firing), interval for checks (speed)
            ncrafting.set_firing(pos, base_firing, firing_int)
        end,
        on_dig = function(pos, node, digger)
            return ncrafting.on_dig_pottery(pos, node, digger, base_firing)
        end,
        on_timer = function(pos, _elapsed)
            --finished product, length
            return ncrafting.fire_pottery(pos, "tech:clay_oil_lamp_unfired", "tech:clay_oil_lamps", base_firing)
        end,
})

minetest.register_node(
    "tech:clay_oil_lamps",{ -- ^[multiply:#493625
        description = S("Clay Oil Lamps (x4)"),
        tiles = {"tech_pottery.png"},
        drawtype = "nodebox",
        stack_max = 1,
        paramtype = "light",
        paramtype2 = "facedir",
        use_texture_alpha = c_alpha.clip,
        node_box = {
            type = "fixed",
            fixed = {
                -- 1
                {-0.5, -0.5, -0.375, -0.25, -0.4375, -0.125}, -- bottom
                {-0.4375, -0.4375, -0.3125, -0.3125, -0.3125, -0.1875}, -- stand
                {-0.5, -0.3125, -0.375, -0.25, -0.125, -0.125}, -- body
                {-0.4375, -0.25, -0.5, -0.3125, -0.125, -0.375}, -- spout
                {-0.4375, -0.1875, -0.125, -0.3125, -0.125, -0.0625}, -- handle
                {-0.4375, -0.3125, -0.125, -0.3125, -0.25, -0.0625}, -- handle
                {-0.4375, -0.3125, -0.0625, -0.3125, -0.125, 0}, -- back handle
                -- 2
                {-0.25, -0.5, 0.125, 0, -0.4375, 0.375}, -- bottom
                {-0.1875, -0.4375, 0.3125, -0.0625, -0.3125, 0.1875}, -- stand
                {-0.25, -0.3125, 0.125, 0, -0.125, 0.375}, -- body
                {-0.1875, -0.25, 0.375, -0.0625, -0.125, 0.5}, -- spout
                {-0.1875, -0.1875, 0.0625, -0.0625, -0.125, 0.125}, -- handle
                {-0.1875, -0.3125, 0.0625, -0.0625, -0.25, 0.125}, -- handle
                {-0.1875, -0.3125, 0, -0.0625, -0.125, 0.0625}, -- back handle
                -- 3
                {0, -0.5, -0.375, 0.25, -0.4375, -0.125}, -- bottom
                {0.0625, -0.4375, -0.3125, 0.1875, -0.3125, -0.1875}, -- stand
                {0, -0.3125, -0.375, 0.25, -0.125, -0.125}, -- body
                {0.0625, -0.25, -0.5, 0.1875, -0.125, -0.375}, -- spout
                {0.0625, -0.1875, -0.125, 0.1875, -0.125, -0.0625}, -- handle
                {0.0625, -0.3125, -0.125, 0.1875, -0.25, -0.0625}, -- handle
                {0.0625, -0.3125, -0.0625, 0.1875, -0.125, 0}, -- back handle
                -- 4
                {0.25, -0.5, 0.125, 0.5, -0.4375, 0.375}, -- bottom
                {0.3125, -0.4375, 0.3125, 0.4375, -0.3125, 0.1875}, -- stand
                {0.25, -0.3125, 0.125, 0.5, -0.125, 0.375}, -- body
                {0.3125, -0.25, 0.375, 0.4375, -0.125, 0.5}, -- spout
                {0.3125, -0.1875, 0.0625, 0.4375, -0.125, 0.125}, -- handle
                {0.3125, -0.3125, 0.0625, 0.4375, -0.25, 0.125}, -- handle
                {0.3125, -0.3125, 0, 0.4375, -0.125, 0.0625}, -- back handle
            }
        },
        groups = {dig_immediate=3, pottery = 1, temp_pass = 1, falling_node = 1},
        sounds = tech.node_sound_earthenware_defaults(),
        on_flood = function(pos, _oldnode, _newnode)
            minetest.add_item(pos, ItemStack("tech:clay_oil_lamps 1"))
            return false
        end,
        drop = "tech:clay_oil_lamp_unlit 4",
})

local spilltimer = {}

minetest.register_entity(
    "tech:oil_spiller", {
        initial_properties = {collisionbox = {0, 0, 0, 0.01, 0.01, 0.01},
                              visual="sprite",
                              textures = { "empty.png" },
                              physical = true
                             },
        on_step = function(self, dtime, _moveresult)
            if not spilltimer[self] then spilltimer[self] = 0 end
            spilltimer[self] = spilltimer[self] + dtime
            self.object:add_velocity(vector.new(0,-9 * dtime, 0))
            if spilltimer[self] > 6 then
                self.object:remove()
            end
        end
})

local function spilled_oil(pos, fuel_lost) -- particles for oil loss
    local amt = math.ceil(1000/3100 * fuel_lost)
    -- ~1 particle per 4.1 units, max 2000 for 100% of fuel, which won't happen
    --print("AMOUNT: ",amt," Fuel_lost: ",fuel_lost)
    local spread = .10 + ( .001 * amt )
    minetest.add_particlespawner({
            amount = math.ceil(amt)+5,
            time = 3,
            minexptime = 3, maxexptime = 4,
            minvel = {x=-spread, y=0, z=-spread},
            maxvel = {x=spread, y=-0.5, z=spread},
            minacc = {x=0, y=-9, z=0},
            maxacc = {x=0, y=-9.5, z=0},
            minsize = .3, maxsize = .3,
            collisiondetection = true,
            attached = minetest.add_entity(pos, "tech:oil_spiller"),
            texture = "tech_vegetable_oil.png",
    })
end

local function register_lamps(desc, oil_lamp_data, alterscript)
    local basedef = {
        description = desc.unlit,
        tiles = {
            "tech_oil_lamp_top.png",
            "tech_oil_lamp_bottom.png",
            "tech_oil_lamp_side.png",
            "tech_oil_lamp_side.png^[transformFX",
            "tech_oil_lamp_front.png",
            "tech_oil_lamp_front.png"
        },
        drawtype = "nodebox",
        stack_max = EXILE.stack_max_medium,
        paramtype = "light",
        sunlight_propagates = true,
        paramtype2 = "facedir",
        use_texture_alpha = c_alpha.clip,
        node_box = {
            type = "fixed",
            fixed = {
                {-0.125, -0.5, -0.125, 0.125, -0.4375, 0.125}, -- bottom
                {-0.0625, -0.4375, -0.0625, 0.0625, -0.3125, 0.0625}, -- stand
                {-0.125, -0.3125, -0.125, 0.125, -0.125, 0.125}, -- body
                {-0.0625, -0.25, 0.125, 0.0625, -0.125, 0.25}, -- spout
                {-0.0625, -0.1875, -0.1875, 0.0625, -0.125, -0.125}, -- handle
                {-0.0625, -0.3125, -0.1875, 0.0625, -0.25, -0.125}, -- handle
                {-0.0625, -0.3125, -0.25, 0.0625, -0.125, -0.1875}, -- handle
            }
        },
        groups = {dig_immediate=3, pottery = 1, temp_pass = 1, falling_node = 1},
        sounds = tech.node_sound_earthenware_defaults(),
        floodable = true,
        on_flood = function(pos, _oldnode, _newnode)
            local fuel = minetest.get_meta(pos):get_int("fuel")
            fuel = (fuel/3100)*100 - math.random(2,4)
            if fuel >= 50 then
                minetest.add_item(pos,oil_lamp_data.fuel_name)
            end
            minetest.add_item(pos, ItemStack(oil_lamp_data.unlit_name))
            return false
        end,
        on_construct = function(pos)
            lightsource.update_fuel_infotext(oil_lamp_data, pos)
        end,
        after_place_node = function(pos, _placer, itemstack, _pointed_thing)
            lightsource.restore_from_inventory(oil_lamp_data, pos, itemstack)
            lightsource.update_fuel_infotext(oil_lamp_data, pos)
        end,
        on_dig = function(pos, _node, digger)
            lightsource.save_to_inventory(oil_lamp_data, pos, digger, false)
        end,
        on_ignite = function(pos, _user)
            lightsource.ignite(oil_lamp_data, pos)
        end,
        on_rightclick = function(pos, _node, clicker, itemstack, _pointed_thing)
            lightsource.refill(oil_lamp_data, pos, clicker, itemstack)
        end,
        on_infotext = lightsource.infotext_get
    }

    local function animated(tname, reverse)
        return {
            name = tname.."_animated.png"..( reverse and "^[transformFX" or ""),
            animation = {type = "vertical_frames",
                         aspect_w = 16, aspect_h = 16, length = 3.3} }
    end

    local litdef = table.copy(basedef) -- Now the lit version
    litdef.description = desc.lit
    litdef.tiles[3] = animated("tech_oil_lamp_side")
    litdef.tiles[4] = animated("tech_oil_lamp_side",true)
    litdef.light_source = 7
    table.insert(litdef.node_box.fixed,
                 {-0.0625, -0.125, 0.25, 0.0625, 0.0625, 0.4375} ) -- flame
    litdef.groups.not_in_creative_inventory = 1
    litdef.on_construct = function(pos)
        lightsource.start_burning(oil_lamp_data, pos)
    end
    litdef.on_timer = function(pos, _elapsed)
        return lightsource.burn_fuel(oil_lamp_data, pos)
    end
    litdef.on_ignite = function(pos, _user)
        lightsource.ignite(oil_lamp_data, pos)
    end
    litdef.on_rightclick = function(pos, _node, clicker,
                                    itemstack, _pointed_thing)
        local rt = lightsource.refill(oil_lamp_data, pos, clicker, itemstack)
        if rt == false then
            lightsource.extinguish(oil_lamp_data, pos)
        end
        lightsource.update_fuel_infotext(oil_lamp_data, pos)
    end

    if alterscript then
        alterscript(basedef, litdef, oil_lamp_data)
    end

    minetest.register_node(oil_lamp_data.unlit_name, basedef)
    litdef.on_dig = function(pos, _node, digger)
            lightsource.save_to_inventory(oil_lamp_data, pos, digger, true)
    end
    minetest.register_node(oil_lamp_data.lit_name, litdef)
end

--fired oil clay lamp

local oil_lamp_desc = lightsource_description.new(
    {lit_name = "tech:clay_oil_lamp", unlit_name = "tech:clay_oil_lamp_unlit",
     fuel_name = "tech:vegetable_oil", max_fuel = 3100,
     burn_rate = 5, refill_ratio = 1/2, put_out_by_moisture = true})
register_lamps(
    {
        unlit = S("Clay Oil Lamp"),
        lit = S("Clay Oil Lamp (Lit)")
    },
    oil_lamp_desc)

--hanging lamp
local hanging_lamp_desc = lightsource_description.new(
    {lit_name = "tech:clay_oil_lamp_hanging",
     unlit_name = "tech:clay_oil_lamp_hanging_unlit",
     fuel_name = "tech:vegetable_oil", max_fuel = 3100,
     burn_rate = 5, refill_ratio = 1/2, put_out_by_moisture = true})
register_lamps(
    {
        unlit = S("Hanging Oil Lamp"),
        lit = S("Hanging Oil Lamp (Lit)")
    },
    hanging_lamp_desc,
    function(udef, ldef, _oil_lamp_data)
        for _, def in pairs({udef, ldef}) do
            table.insert(def.node_box.fixed, -- add the string it hangs from
                         {-0.001, -0.125, -0.1875, 0.001, 0.5, 0.125} )
            def.groups.attached_node = 1
            def.groups.falling_node = nil
            def.paramtype2 = "wallmounted" -- hangs upside down, so
            for i = 1,#def.node_box.fixed do -- Invert the nodebox
                def.node_box.fixed[i][2] = def.node_box.fixed[i][2] * -1
                def.node_box.fixed[i][5] = def.node_box.fixed[i][5] * -1
            end
            local tmptile = def.tiles[1] -- swap the top and bottom textures
            def.tiles[1] = def.tiles[2]
            def.tiles[2] = tmptile
            for i = 1,#def.tiles do -- and invert the textures
                if type(def.tiles[i]) == "string" then
                    def.tiles[i] = def.tiles[i].."^[transformFY"
                else
                    def.tiles[i].name = def.tiles[i].name.."^[transformFY"
                end
            end
            def.node_placement_prediction = ""
            def.on_place = function(itemstack, placer, pointed_thing)
                local dest = pointed_thing.above
                local over = vector.new(dest.x, dest.y + 1,dest.z)
                local hangfrom = minetest.get_node(over).name
                local valid = false
                if minetest.registered_nodes[hangfrom]
                    and minetest.registered_nodes[hangfrom].walkable == true then
                    valid = true
                end
                if not valid then
                    return itemstack
                end
                return minetest.item_place_node(itemstack, placer, pointed_thing, 0)
            end
            def.preserve_metadata = function(pos, _oldnode, oldmeta, drops, imeta)
                if not (oldmeta and oldmeta.fuel) then return end
                imeta = imeta or drops[1]:get_meta()
                local loss =   100 + oldmeta.fuel * .05 * math.random(1,6)
                -- 100 + 5-30% loss
                local fuel = oldmeta.fuel - loss
                spilled_oil(pos, loss)
                imeta:set_string("fuel", fuel)
            end
            def.on_rotate = false
        end
    end
)


--unfired watering can
minetest.register_node(
    "tech:clay_watering_can_unfired", {
        description = S("Clay Watering Can (unfired)"),
        tiles = {
            "nodes_nature_clay.png",
            "nodes_nature_clay.png",
            "nodes_nature_clay.png",
            "nodes_nature_clay.png",
            "nodes_nature_clay.png",
            "nodes_nature_clay.png"
        },
        drawtype = "nodebox",
        stack_max = EXILE.stack_max_bulky,
        paramtype = "light",
        node_box = {
            type = "fixed",
            fixed = {
                -- lid
                {-0.2, 0.2,-0.2, 0.2, 0.3, 0.2},
                -- handle
                {-0.05, 0.05, -0.25, 0.05, 0.15, -0.45}, -- upper
                {-0.05, -0.1, -0.35, 0.05, 0.05, -0.45}, -- mid
                {-0.05, -0.2, -0.25, 0.05, -0.1, -0.45}, -- low
                -- spout
                {-0.1, 0.1, 0.25, 0.1, 0.2, 0.5}, -- upper
                {-0.1, -0.4, 0.25, 0.1, 0.1, 0.4},
                -- body
                {-0.25, -0.4, -0.25, 0.25, 0.2, 0.25},
                -- base
                {-0.3, -0.5,-0.4, 0.3, -0.35, 0.4},
            }
        },
        groups = {dig_immediate=3, temp_pass = 1, heatable = 20,
                  timer = firing_int},
        sounds = nodes_nature.node_sound_stone_defaults(),
        on_construct = function(pos)
            --length(i.e. difficulty of firing), interval for checks (speed)
            ncrafting.set_firing(pos, base_firing, firing_int)
        end,
        on_dig = function(pos, node, digger)
            return ncrafting.on_dig_pottery(pos, node, digger, base_firing)
        end,
        on_timer = function(pos, _elapsed)
            --finished product, length
            return ncrafting.fire_pottery(pos,
                                          "tech:clay_watering_can_unfired",
                                          "tech:clay_watering_can", base_firing)
        end,
})


---------------------------------------
--Recipes

--
--Hand crafts (crafting spot)
--

--Pot from clay
crafting.register_recipe({
        type = {"crafting_spot","hand_pottery"},
        output = "tech:clay_water_pot_unfired 1",
        items = {"nodes_nature:clay_wet 2"},
        level = 1,
        always_known = true,
})

crafting.register_recipe({
        type = {"mixing_spot","hand_pottery"},
        output = "nodes_nature:clay 2",
        items = {"tech:clay_water_pot_unfired 1"},
        level = 1,
        always_known = true,
})


--storage Pot from clay
crafting.register_recipe({
        type = {"crafting_spot","hand_pottery"},
        output = "tech:clay_storage_pot_unfired",
        items = {"nodes_nature:clay_wet 4"},
        level = 1,
        always_known = true,
})

crafting.register_recipe({
        type = {"mixing_spot","hand_pottery"},
        output = "nodes_nature:clay 4",
        items = {"tech:clay_storage_pot_unfired 1"},
        level = 1,
        always_known = true,
})

--oil lamp
crafting.register_recipe({
        type = {"crafting_spot","hand_pottery"},
        output = "tech:clay_oil_lamp_unfired 1",
        items = {"nodes_nature:clay_wet"},
        level = 1,
        always_known = true,
})

crafting.register_recipe({
        type = {"mixing_spot","hand_pottery"},
        output = "nodes_nature:clay",
        items = {"tech:clay_oil_lamp_unfired 1"},
        level = 1,
        always_known = true,
})

--Hanging oil lamp
crafting.register_recipe({
        type = {"crafting_spot","hand_pottery"},
        output = "tech:clay_oil_lamp_hanging_unlit 1",
        items = {"tech:clay_oil_lamp_unlit", "group:fibrous_plant"},
        level = 0,
        always_known = true,
        sound = {name="nodes_nature_grass_footstep", pitch={0.85, 1.1}, gain=0.4}
})
--Break up pots
crafting.register_recipe({
        type = {"mixing_spot","hand_pottery"},
        output = "tech:ruined_pottery_slab",
        items = {"group:pottery"},
        level = 1,
        always_known = true,
        -- TODO: see about using glass breakiing sounds
        sound = {name = "tech_rock_crush", pitch = {1.1, 1.6}}
})

--Combine broken pottery slabs and vice versa
crafting.register_recipe({
        type = {"mixing_spot","hand_pottery"},
        output = "tech:ruined_pottery",
        items = {"tech:ruined_pottery_slab 2"},
        level = 0,
        always_known = true,
        sound = {name = "tech_rock_crush", pitch = {0.8, 0.95}}
})

crafting.register_recipe({
        type = {"mixing_spot","hand_pottery"},
        output = "tech:ruined_pottery_slab 2",
        items = {"tech:ruined_pottery"},
        level = 0,
        always_known = true,
        sound = {name = "tech_rock_crush", pitch = {0.8, 0.95}}
})

-- clay watering can
crafting.register_recipe({
        type = {"crafting_spot","hand_pottery"},
        output = "tech:clay_watering_can_unfired 1",
        items = {"nodes_nature:clay_wet 3"},
        level = 1,
        always_known = true,
})

crafting.register_recipe({
        type = {"crafting_spot","hand_pottery"},
        output = "nodes_nature:clay 3",
        items = {"tech:clay_watering_can_unfired 1"},
        level = 1,
        always_known = true,
})
