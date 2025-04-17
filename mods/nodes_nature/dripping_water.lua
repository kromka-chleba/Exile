-------------------------------------------------------------------------
--Dripping Water
--underground drinkable water drops
-------------------------------------------------------------------------
local random = math.random

local S = minetest.get_translator("nodes_nature")

--Drop entities
local drop_entity = {
    _desc = S("Water drop"),
    initial_properties = {
        hp_max = 2,
        physical = true,
        collide_with_objects = false,
        collisionbox = {-0.05,-0.05,-0.05,0.05,0.05,0.05},
        visual = "cube",
        visual_size = {x=0.05, y=0.1},
        textures = {"nodes_nature_freshwater.png",
                    "nodes_nature_freshwater.png",
                    "nodes_nature_freshwater.png",
                    "nodes_nature_freshwater.png",
                    "nodes_nature_freshwater.png",
                    "nodes_nature_freshwater.png"},
        spritediv = {x=1, y=1},
        initial_sprite_basepos = {x=0, y=0},
    },

    sounds = {
        drip = {
            name = "nodes_nature_water_drip", gain = {0.5, 2}
        },
        sploosh = {
            name = "nodes_nature_place_water", gain = {0.1,0.2}, pitch = {1.5, 2.4}
        },
    },

    on_activate = function(self, staticdata)
        self.object:set_sprite({x=0,y=0}, 1, 1, true)
        self.object:set_armor_groups({immortal=1})
        self.ownpos = self.object:get_pos() -- we literally only need this once (until we fall), so save it!
        self.check_above, self.check_in = 0.8, 1.2
    end,

    fall_detach = function(self)
        self.falling = true
        self.ownpos = nil
        self.object:set_acceleration({x=0, y=-5, z=0})
    end,

    on_step = function(self, dtime, moveresult)
        -- random chance of falling
        if not self.falling then
            if random(1,444) == 1 then -- 1 in 444 chance
                return self:fall_detach(self)
            end
        end

        -- with ownpos available
        local ownpos = self.ownpos or self.object:get_pos()
        if not self.falling then
            -- check above somewhat regularly
            self.check_above = self.check_above - dtime
            if self.check_above < 0 then
                local above = minimal.get_nodedef({x=ownpos.x, y=ownpos.y+0.5,z=ownpos.z}) or {name="air"}
                -- we're falling!!!! aaaaa!!!
                if above.name == "air" or above.drawtype == "airlike" then
                    return self:fall_detach()
                end
                self.check_above = 0.8 -- reset counter
            end
            -- check within somewhat regularly
            self.check_in = self.check_in - dtime
            if self.check_in < 0 then
                local inside = minimal.get_nodedef(ownpos) or {name="air"}
                -- hey! you placed a block into me!!! no drip for u
                if not (inside.name == "air" or inside.drawtype == "airlike") then
                    self.object:remove()
                end
            end
            return -- nothing interesting, return
        end

        -- we're actually falling!
        if moveresult and moveresult.collides then
            local node_pos = moveresult.collisions and moveresult.collisions[1]
            -- dripped onto something
            if node_pos then
                if self.sounds and self.sounds.drip then
                    minimal.sound_play(minimal.merge_tables(self.sounds.drip, {pos=ownpos}))
                end
                return self.object:remove()
            end
        end
        -- let's just keep checking what we're in
        local inside = minimal.get_nodedef(ownpos) or {name="air"}
        -- splish splash
        if (inside.drawtype == "liquid" or inside.drawtype == "flowingliquid") then
            if self.sounds and self.sounds.sploosh then
                minimal.sound_play(minimal.merge_tables(self.sounds.sploosh, {pos=ownpos}))
            end
            return self.object:remove()
        end
    end,

    on_punch=function(self, puncher, time_from_last_punch,
                      tool_capabilities, dir)
        --drink
        local meta = puncher:get_meta()
        if not meta then return end --mobs can punch, but can't drink
        local pos = puncher:get_pos()
        local thirst = meta:get_int("thirst")
        --only drink if thirsty
        if thirst < 100 then

            local water = math.random(1,10)
            thirst = thirst + water
            if thirst > 100 then
                thirst = 100
            end

            meta:set_int("thirst", thirst)
            minetest.sound_play("nodes_nature_slurp",
                                {pos = pos, max_hear_distance = 3, gain = 0.1})
            self.object:remove()

            --food poisoning
            if random() < 0.005 then
                HEALTH.add_new_effect(puncher, {"Food Poisoning", 1})
            end

            --parasites
            if random() < 0.001 then
                HEALTH.add_new_effect(puncher, {"Intestinal Parasites"})
            end

        end
    end,
}

minetest.register_entity("nodes_nature:drop_water", drop_entity)


--Create drop
minetest.register_abm({
        label = "Dripping Water",
        nodenames = {"group:stone", "group:soft_stone"},
        --neighbors = {"group:water"},
        interval = 27,
        chance = 120,
        action = function(pos)

            if pos.y < 200
                and pos.y > -1000 then
                local nb = minetest.get_node({x=pos.x,
                                              y=pos.y-1,
                                              z=pos.z}).name
                if nb == 'air' then
                    local nb2 = minetest.get_node({x=pos.x,
                                                   y=pos.y-2,
                                                   z=pos.z}).name
                    if nb2 == 'air' then
                        local i = math.random(-35,35) / 100
                        minetest.add_entity({x=pos.x + i,
                                             y=pos.y-0.501,
                                             z=pos.z + i},
                            "nodes_nature:drop_water")
                    end
                end
            end
        end,
})
