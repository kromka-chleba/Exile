--------------------------------------------------------------------------
--CRAFTS
--------------------------------------------------------------------------
--[[
    Carcasses:
    Invertebrate,
    Fish,
    Bird,
    (Mammal, Lizard)


    Sizes:
    small, large

    --
    leather, Bone, skin, sinews, feathers?
]]
animals = animals

-- Internationalization
local S = animals.S

local random = math.random
local floor = math.floor
local abs = math.abs
--------------------------------------------------------------------------
--Carcasses
-------------------------------------------
local box_small_invert = {
    {-0.125, -0.5, -0.1875, 0.125, -0.4375, 0.1875}, -- NodeBox1
    {-0.0625, -0.4375, -0.1875, 0.0625, -0.375, 0.1875}, -- NodeBox2
    {-0.0625, -0.5, -0.25, 0.0625, -0.4375, -0.1875}, -- NodeBox3
    {-0.0625, -0.5, 0.1875, 0.0625, -0.4375, 0.25}, -- NodeBox4
}

local box_large_invert ={
    {-0.1875, -0.5, -0.25, 0.1875, -0.375, 0.25}, -- NodeBox1
    {-0.125, -0.375, -0.25, 0.125, -0.3125, 0.25}, -- NodeBox2
    {-0.0625, -0.5, -0.375, 0.0625, -0.375, -0.25}, -- NodeBox3
    {-0.0625, -0.5, 0.25, 0.0625, -0.375, 0.375}, -- NodeBox4
}

local box_small_bird = {
    {-0.125, -0.5, -0.1875, 0.125, -0.375, 0.125}, -- NodeBox1
    {-0.0625, -0.375, -0.1875, 0.0625, -0.3125, 0.0625}, -- NodeBox2
    {-0.0625, -0.5, -0.3125, 0.0625, -0.375, -0.1875}, -- NodeBox3
    {-0.0625, -0.5, 0.125, 0.0625, -0.4375, 0.25}, -- NodeBox4
    {0.125, -0.5, -0.125, 0.3125, -0.4375, 0}, -- NodeBox5
    {-0.3125, -0.5, -0.125, -0.125, -0.4375, 0}, -- NodeBox6
    {0.125, -0.5, 0.0625, 0.1875, -0.4375, 0.25}, -- NodeBox7
    {-0.1875, -0.5, 0.0625, -0.125, -0.4375, 0.25}, -- NodeBox8
}

local box_small_fish = {
    {-0.125, -0.5, -0.1875, 0.125, -0.4375, 0.1875}, -- NodeBox1
    {-0.0625, -0.4375, -0.1875, 0.0625, -0.375, 0.1875}, -- NodeBox2
    {-0.0625, -0.5, -0.3125, 0.0625, -0.4375, -0.1875}, -- NodeBox3
    {-0.0625, -0.5, 0.1875, 0.0625, -0.4375, 0.375}, -- NodeBox4
    {0.125, -0.5, -0.125, 0.1875, -0.4375, 0.125}, -- NodeBox9
    {-0.1875, -0.5, -0.125, -0.125, -0.4375, 0.125}, -- NodeBox10
}

local box_large_fish = {
    {-0.25, -0.5, -0.3125, 0.25, -0.375, 0.3125}, -- NodeBox1
    {-0.125, -0.375, -0.3125, 0.125, -0.3125, 0.25}, -- NodeBox2
    {-0.125, -0.5, -0.4375, 0.125, -0.375, -0.3125}, -- NodeBox3
    {-0.125, -0.5, 0.3125, 0.125, -0.375, 0.4375}, -- NodeBox4
    {0.25, -0.5, 0, 0.375, -0.4375, 0.25}, -- NodeBox9
    {-0.375, -0.5, 0, -0.25, -0.4375, 0.25}, -- NodeBox10
    {-0.0625, -0.3125, -0.1875, 0.0625, -0.25, 0}, -- NodeBox11
}

local list = {
    {
        "invert_small",
        S("@1 Invertebrate",S("Small")),
        box_small_invert,
        minimal.stack_max_medium,
        80,
    },
    {
        "invert_large",
        S("@1 Invertebrate",S("Large")),
        box_large_invert,
        minimal.stack_max_medium/4,
        70,
    },
    {
        "bird_small",
        S("@1 Bird",S("Small")),
        box_small_bird,
        minimal.stack_max_medium/4,
        70,
    },
    {
        "fish_small",
        S("@1 Fish",S("Small")),
        box_small_fish,
        minimal.stack_max_medium/4,
        70,
    },
    {
        "fish_large",
        S("@1 Fish",S("Large")),
        box_large_fish,
        minimal.stack_max_bulky,
        65,
    },
}

-- core.item_drop does not provide itemstack object, this does!
local function item_drop(itemstack, dropper, pos)
    local dropper_is_player = core.is_player(dropper)
    local p = table.copy(pos)
    local cnt = itemstack:get_count()
    p.y = dropper_is_player and p.y + 1.2 or p.y
    local item = itemstack:take_item(cnt)
    local obj = core.add_item(p, item)
    if obj then
        if dropper_is_player then
            local dir = dropper:get_look_dir()
            dir.x = dir.x * 2.9
            dir.y = dir.y * 2.9 + 2
            dir.z = dir.z * 2.9
            obj:set_velocity(dir)
            obj:get_luaentity().dropped_by = dropper:get_player_name()
        end
        -- return object as 2nd parameter
        return itemstack, obj
    end
    -- If we reach this, adding the object to the
    -- environment failed
end

local meat_placing
meat_placing = function(pos, def, tries)
    tries = tries and tries + 1 or 0 -- start at 0
    pos.y = pos.y + tries
    if tries > 4 then return end -- stop trying!
    local atdef = minimal.get_nodedef(pos)
    -- can replace nil nodes or buildable_to nodes, otherwise try looking up more
    if atdef and not atdef.buildable_to then
        return meat_placing(pos, def, tries)
    end
    core.set_node(pos, {name = def.name})
    local place_sound = def.sounds and def.sounds.place
    if place_sound then
        core.sound_play(place_sound.name, minimal.merge_tables(place_sound, {pos = pos}))
    end
    -- check if we should fall
    core.check_single_for_falling(pos)
end

local meat_dropping
-- item, how long has been 0
meat_dropping = function(def, obj, was0)
    if obj and not def then obj:remove() end -- no definition, DESTROY
    local vel = obj and obj:get_velocity()
    if not vector.check(vel) then return end -- we got deletus
    vel = abs(vel.x)+abs(vel.y)+abs(vel.z)
    was0 = vel == 0 and (was0 and was0 + 1 or 1) or 0
    -- checks if have been standing still during 2 previous checks
    -- time to try placing
    --core.log(was0)
    if was0 > 2 then
        local pos = obj:get_pos()
        pos = vector.new(floor(pos.x + 0.5), floor(pos.y + 0.5), floor(pos.z + 0.5))
        -- figure out if we should keep trying to place the meats
        local ent = obj:get_luaentity()
        local itemstack = ent and ent.itemstring
        itemstack = itemstack and itemstack ~= '' and ItemStack(itemstack)
        local count = itemstack:get_count()
        obj:remove() -- let's remove now that we're trying to place
        -- oh... there's more of us, uhhh
        if count > 1 then
            itemstack:set_count(count - 1)
            -- randomize position
            pos.x = pos.x + random(-1, 1)
            pos.z = pos.z + random(-1, 1)
            meat_dropping(def, core.add_item(pos, itemstack)) -- begin the whole process
        end
        meat_placing(pos, def)
    end
    core.after(0.3*(random(50,150)/100), meat_dropping, def, obj, was0)
end


for i in ipairs(list) do
    local name = list[i][1]
    local desc = list[i][2]
    local box = list[i][3]
    local stack = list[i][4]
    local heat = list[i][5]

    -- when defining carcass type, add a space of 4 (1 = invert, +4 = bird = 5)
    -- unknown carcass is 21
    local carcass = name:match("invert") and 1 or name:match("bird") and 5 or
      name:match("fish") and 9 or name:match("reptile") and 13 or
      name:match("mammal") and 17 or 21
    -- small would be the base value - 1 for invert, 4 for bird, 7 for fish
    carcass = carcass + (name:match("medium") and 1 or name:match("large") and 2 or name:match("gargantuan") and 3 or 0)

    --raw
    minetest.register_node("animals:carcass_"..name, {
                               description = S('@1 Carcass', desc),
                               tiles = {"animals_carcass.png"},
                               drawtype = "nodebox",
                               paramtype = "light",
                               node_box = {
                                   type = "fixed",
                                   fixed = box
                               },
                               stack_max = stack/2,
                               groups = {snappy = 3, dig_immediate = 3,
                                         falling_node = 1, temp_pass = 1,
                                         raw_cooked = 1, heatable = heat,
                                         carcass = carcass, edible = 1},
                               sounds = animals.node_sound_meat_defaults(),
                               -- player's dropping meat onto the ground
                               on_drop = function(itemstack, dropper, pos)
                                    local dropped,itemdef = nil, itemstack and itemstack:get_definition()
                                    itemstack, dropped = item_drop(itemstack, dropper, pos)
                                    if itemdef and itemdef.placeable_item_drop then
                                        itemdef.placeable_item_drop(itemdef, dropped)
                                    end
                                    return itemstack
                               end,
                               -- what we should do if we're dropped but can be placed (ran on drop)
                               -- ran in on_drop and in animals.handle_drops
                               placeable_item_drop = function(def, obj)
                                    return meat_dropping(def, obj)
                               end
    })

    --cooked
    minetest.register_node("animals:carcass_"..name.. "_cooked", {
                               description = S('Cooked @1', desc),
                               tiles = {"nodes_nature_silt.png"},
                               drawtype = "nodebox",
                               paramtype = "light",
                               node_box = {
                                   type = "fixed",
                                   fixed = box
                               },
                               stack_max = stack,
                               groups = {snappy = 3, dig_immediate = 3,
                                         falling_node = 1, temp_pass = 1,
                                         raw_cooked = 2, carcass = carcass,
                                         edible = 1},
                               sounds = animals.node_sound_meat_cooked_defaults(),
    })

    --burned
    minetest.register_node("animals:carcass_"..name.. "_burned", {
                               description = S('Burned @1', desc),
                               tiles = {"animals_carcass_burned.png"},
                               drawtype = "nodebox",
                               paramtype = "light",
                               node_box = {
                                   type = "fixed",
                                   fixed = box
                               },
                               stack_max = stack,
                               groups = {snappy = 3, dig_immediate = 3,
                                         falling_node = 1, temp_pass = 1,
                                         raw_cooked = 3, carcass = carcass,
                                         edible = 1},
                               sounds = nodes_nature.node_sound_defaults(),
    })

    HEALTH.add_food_hooks("animals:carcass_"..name)
    HEALTH.add_food_hooks("animals:carcass_"..name.. "_cooked")
    HEALTH.add_food_hooks("animals:carcass_"..name.. "_burned")
end
