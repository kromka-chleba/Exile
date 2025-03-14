-- An invisible entity that prevents players from falling in the hole
--  that needs to be filled for the "place button" (right click) step of
--  the controls stage

-- When the two blocks of sand are dropped in correctly, the salt water
--  node rises to the bottom of the entity, and it will allow safe passage

local loaded_ents = {}

local blocker_ent = {
    initial_properties = {collisionbox = {-0.25, -0.025, -0.25,
                                          0.25, 0.25, 0.25},
                          visual="sprite",
                          textures = { "empty.png" },
                          pointable = false,
                          physical = true,
                          collide_with_objects = true,
                         },
    on_activate = function(self)
        local pos = self.object:get_pos()
        self.poscheck = vector.new(pos.x, pos.y - 1, pos.z)
    end,
    on_step = function(self, dtime, moveresult)
        if self.disabled then -- Old entity, or done existing
            self.object:remove()
            return
        end
        self.timer = (self.timer or 0 ) + dtime
        if self.timer < .5 then return end
        self.timer = 0

        local node = minetest.get_node(self.poscheck)
        local solid = self.object:get_properties().physical
        local water = minetest.get_item_group(node.name, "water") > 0
        if water and solid then
            self.object:set_properties({ collide_with_objects = false })
            self.disabled = true
        elseif not water and not solid then
            self.object:set_properties({ collide_with_objects = true })
        end
    end,
}
minetest.register_entity("tutorial_exile:place_blocker", blocker_ent)

if minetest.settings:get("exile_debug") ~= "true" then return end

minetest.register_chatcommand(
    "place_blocker",{
        privs = "server",
        func = function(name,param)
            local pointed = minimal.get_pointed_thing(name)
            local tgt = vector.round(pointed.above)
            local ent = minetest.add_entity(tgt, "tutorial_exile:place_blocker")
            if not ent then return false, "Failed to place!" end
            ent:set_properties({ textures = {"metal_plasma.png"} })
            ent:get_luaentity().debug = true
            table.insert(loaded_ents , ent)
        end

})
minetest.register_chatcommand(
    "clear_blockers",{
        privs = "server",
        func = function(name,param)
            for i = 1, #loaded_ents do
                loaded_ents[i]:remove()
            end
        end
})
