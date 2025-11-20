-------------------------------------------------------------------------
--Dripping Water
--underground drinkable water drops
-------------------------------------------------------------------------
local random = math.random

local S = minetest.get_translator("nodes_nature")

--Drop entities
local drop_entity = {
    _desc = S("Water drop"),
    drop_base_size = 0.05,
    initial_properties = {
        hp_max = 2,
        physical = false,
        collide_with_objects = false,
        visual = "cube",
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
            name = "nodes_nature_water_drip", gain = {0.5, 2}, pitch = {0.75, 1.05}
        },
        sploosh = {
            name = "nodes_nature_water_drip_liquid", gain = {0.3,1.5}, pitch = {0.75, 1.05}
        },
        consume = {
            name = "nodes_nature_slurp", max_hear_distance = 3, gain = 0.1, pitch = {0.9,1.1}
        }
    },

    on_activate = function(self, staticdata)
        self.object:set_sprite({x=0,y=0}, 1, 1, true)
        self.object:set_armor_groups({immortal=1})
        self.ownpos = self.object:get_pos() -- we literally only need this once (until we fall), so save it!
        self.check_above, self.check_in = 0.8, 1.2 -- setting up checks for on_step
        -- set thirst value and water drop size
        self.thirst = random(1,10) -- randomize between 1 to 10 units of thirst
        local props = self.object:get_properties()
        -- this calculation makes it so the water droplet is sized proportionately to the amount of thirst it gives
        local size = self.drop_base_size * (self.thirst / 10 + .5)
        props.visual_size = {x = size, y = size * 2}
        props.collisionbox = {-size,-size,-size, size,size,size}
        props.selectionbox = props.collisionbox
        self.object:set_properties(props)
    end,

    fall_detach = function(self)
        self.falling = true
        self.ownpos = nil
        self.object:set_acceleration({x=0, y=-5, z=0})
        -- make physical on drop
        local props = self.object:get_properties()
        props.physical = true
        self.object:set_properties(props)
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
                local above = minimal.get_nodedef({x=ownpos.x, y=ownpos.y+0.5,z=ownpos.z})
                -- we're falling!!!! aaaaa!!!
                if above and above.name and minimal.is_group(above.name, "air") then
                    return self:fall_detach()
                end
                self.check_above = 0.8 -- reset counter
            end
            -- check within somewhat regularly
            self.check_in = self.check_in - dtime
            if self.check_in < 0 then
                local inside = minimal.get_nodedef(ownpos)
                -- hey! you placed a block into me!!! no drip for u
                if not (inside and inside.name and minimal.is_group(inside.name, "air") ) then
                    self.object:remove()
                end
            end
            return -- nothing interesting, return
        end

        -- we're actually falling!
        -- collided with something
        if moveresult and moveresult.collides then
            local node_pos = moveresult.collisions and moveresult.collisions[1]
            node_pos = node_pos and node_pos.node_pos
            -- dripped onto something
            if node_pos then
                local nodedef, node = minimal.get_nodedef(node_pos)
                -- will not play sound automatically for any nodes with this callback
                if nodedef and nodedef.on_water_drop_hit then
                    nodedef.on_water_drop_hit(node_pos, node, nodedef, self)
                -- drip drop
                elseif self.sounds and self.sounds.drip then
                    minimal.sound_play(minimal.merge_tables(self.sounds.drip, {pos=ownpos}))
                end
                return self.object:remove()
            end
        end
        -- let's just keep checking what we're in
        local inside, node = minimal.get_nodedef(ownpos)
        -- splish splash
        if inside and (inside.drawtype == "liquid" or inside.drawtype == "flowingliquid") then
            -- ditto for node hits
            if inside.on_water_drop_splash then
                -- ownpos will be the position hit, not the exact node pos!
                inside.on_water_drop_splash(ownpos, node, inside, self)
            elseif self.sounds and self.sounds.sploosh then
                minimal.sound_play(minimal.merge_tables(self.sounds.sploosh, {pos=ownpos}))
            end
            return self.object:remove()
        end
    end,

    on_punch=function(self, puncher, time_from_last_punch,
                      tool_capabilities, dir)
        --drink
        if not core.is_player(puncher) then return end -- not player, begoneth!
        local meta = puncher:get_meta()
        if not meta then return end -- oh... this is awkward
        local pos = puncher:get_pos()
        local thirst = meta:get_int("thirst")
        --only drink if thirsty
        if thirst < 100 then

            HEALTH.modify_int(puncher, meta, "thirst", self.thirst)
            if self.sounds and self.sounds.consume then
                minimal.sound_play(minimal.merge_tables(self.sounds.consume, {object = puncher}))
            end
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
