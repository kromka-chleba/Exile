-- An invisible entity that prevents players from falling in the hole
--  that needs to be filled for the "place button" (right click) step of
--  the controls stage

-- When the two blocks of sand are dropped in correctly, the salt water
--  node rises to the bottom of the entity, and it will allow safe passage

local blocker_ent = {
    initial_properties = {collisionbox = {-0.15, -0.025, -0.15,
                                          0.15, 0.5, 0.15},
                          visual="sprite",
                          textures = { "empty.png" },
                          pointable = false,
                          physical = true,
                          collide_with_objects = true,
                         },
    on_activate = function(self)
        local pos = self.object:get_pos()
        local nearby = core.get_objects_inside_radius(pos, 1.5)
        for i = 1, #nearby do
            if nearby[i] ~= self.object then -- different objectref
                nearby[i]:remove()
            end
        end
        self.poscheck = vector.new(pos.x, pos.y - 1.5, pos.z)

        local checkpos = vector.new(pos.x, pos.y - 3.5, pos.z)
        -- Sometimes the water node is missing? Recreate it if it's gone
        core.after(2, function()
                       local node = core.get_node(checkpos)
                       if node.name == "air" then
                           core.set_node(checkpos,
                                         { name =
                                               "nodes_nature:freshwater_source"}
                           )
                       end
        end)

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

local loaded_ents = {}

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
            table.insert(loaded_ents, ent)
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
