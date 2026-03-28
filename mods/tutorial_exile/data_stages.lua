tutorial = tutorial
local stage = ...

local shelter_entry, shelter_exit = loadfile(
    core.get_modpath("tutorial_exile").."/shelter.lua")(stage)

return
    {
        [0] = {
            name = "Landing zone",
            schem = "",
            size = vector.new(50,1,50),
            -- location is relative to instance base pos
            location = vector.new(0,9260,0), -- but this one's hardcoded
            -- player start pos, relative to location
            start = vector.new(17,9253,25),
            facing = 5.517, -- look direction in radians
            splashicon = nil, -- These are displayed on entering
            splashtext = "Welcome to the tutorial",

            -- examples for entry/exit functions:
            entry = function(self, player, name, instance)
                -- self is this stage data, instance is the instance data +offset
                print(name," is entering ",self.name)
                local privs = core.get_player_privs(name)
                privs.interact = nil
                core.set_player_privs(name, privs)
                --player:set_armor_groups({ immortal = 1})
            end,
            exit = function(self, player, name, instance)
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
            location = vector.new(0,0,0),
            start = vector.new(3,5,15),
            facing = 4.07,
            entry = function(self, player, name, instance)
                local tgt = instance.offset -- absolute map location
                    + vector.new(6,4.5,9) -- where to put the entity
                local ent = minetest.get_objects_inside_radius(tgt, 1)
                if not ent or #ent == 0 then
                    minetest.add_entity( tgt, "tutorial_exile:place_blocker" )
                end
            end,
        },
        [2] = {
            name = "Movement",
            schem = "movement",
            size = vector.new(46, 28, 22),
            location = vector.new(80,0,0),
            start = vector.new(5,2,16),
            facing = 2.023,
            exit = function(self, player, name, instance)
                --minetest.chat_send_player(name, "Area complete")
            end,
        },
        [3] = {
            name = "Shelter",
            schem = "shelter",
            size = vector.new(52,21,49),
            location = vector.new(0,0,80),
            start = vector.new(46,4,10),
            facing = 1.5,
            entry = shelter_entry,
            exit = shelter_exit
        },
        [4] = {
            name = "Crafting",
            schem = "craft",
            size = vector.new(11,15,41),
            location = vector.new(80,0,80),
            start = vector.new(5,3,39),
            facing = 3.25,
            entry = function(self, player, name, instance)
                climate.set_weather_override(name, nil, "")
            end,
            splashicon = "tech_paint_lw_weave.png^[resize:32x32",
            splashtext = "Crafting",
        },
        [5] = {
            name = "Spirit",
            schem = "spirit",
            size = vector.new(87,24,20),
            location = vector.new(0,0,140),
            start = vector.new(3,7,7),
            facing = 4.7,
            splashicon = "tech_paint_lw_fire.png^[resize:32x32",
            splashtext = "The Spirit of Exile",
        }
    }
