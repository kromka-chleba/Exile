local shelter_entry, shelter_exit = dofile(
    minetest.get_modpath("tutorial_exile").."/shelter.lua")

return
    {
        [0] = {
            name = "Landing zone",
            schem = "",
            size = vector.new(50,1,50),
            -- player start pos, relative to location
            start = vector.new(17,9253,25),
            -- location is relative to instance base pos
            location = vector.new(0,9260,0), -- but this one's hardcoded

            -- examples for entry/exit functions:
            entry = function(self, player, name)
                -- self is the instance data, incl offset
                print(name," is entering ",self.name)
                local privs = core.get_player_privs(name)
                privs.interact = false
                core.set_player_privs(name, privs)
                --player:set_armor_groups({ immortal = 1})
            end,
            exit = function(self, player, name)
                local privs = core.get_player_privs(name)
                privs.interact = true
                core.set_player_privs(name, privs)
                --player:set_armor_groups({ immortal = 0})
            end,
        },
        [1] = {
            name = "Controls",
            schem = "controls",
            size = vector.new(12,9,18),
            start = vector.new(3,5,15),
            location = vector.new(0,0,0),
        },
        [2] = {
            name = "Movement",
            schem = "movement",
            size = vector.new(46, 28, 22),
            start = vector.new(5,3,16),
            location = vector.new(80,0,0),
            exit = function(self, player, name)
                minetest.chat_send_player(name, "Area complete")
            end,
        },
        [3] = {
            name = "Shelter",
            schem = "shelter",
            size = vector.new(52,21,49),
            start = vector.new(46,4,8),
            location = vector.new(0,0,80),
            entry = shelter_entry,
            exit = shelter_exit
        },
        [4] = {
            name = "Fire+Air",
            schem = "fire+air",
            size = vector.new(19,7,23),
            start = vector.new(5,5,5),
            location = vector.new(80,0,80),
        },
        [7] ={
            name = "Crafting",
            schem = "crafting",
            size = vector.new(36,20,43),
            start = vector.new(5,5,5),
            location = vector.new(0,80,0),
        },
    }
