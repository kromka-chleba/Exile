
------------------------------------
--TOOL CRAFTS

--[[
    Tool values based on multipliers from hand values
    Tools can dig even unsuitable types, if you would use it if you were desperate.
    Tools get increased wear on unsuitable tasks (e.g. chopping wood with a sword would ruin the sword)
    Therefore many tools can be used by the player as multi-purpose,
    which should be useful given the limits on resources and space they face.


]]

-- Declare globals
minimal = minimal
crafting = crafting
nodes_nature = nodes_nature
tech = tech


-- Internationalization
local S = tech.S

local c_alpha = minimal.compat_alpha
local soil = nodes_nature.soil

local base_use = 500
local base_punch_int = minimal.hand_punch_int

-----------------------------------

--Tool placing

--Places a tool
local function place_tool(itemstack, placer, pointed_thing)
    -- check if the pointed item has on_rightclick ... (will run it automatically)
    local to_return = minimal.on_rightclick(itemstack, placer, pointed_thing)
    if to_return ~= false then
        -- if not false then return the result (rightclick ran successfully)
        return to_return
    end
    local idef = itemstack:get_definition()
    local placed_name = idef._tool_placed or itemstack:get_name().."_placed" -- get placed name
    local place_item = ItemStack(placed_name)
    if not core.registered_nodes[placed_name] then return end -- don't do anything if we can't actually place it
    local above = pointed_thing.above
    local abdef = minimal.get_nodedef(above) -- above def
    local ufdef = minimal.get_nodedef(above + vector.new(0,-1,0)) -- under_front def
    if not (abdef and ufdef) then return end -- not a defined node
    -- check if not walkable - there's empty space over the node
    --  (air, water, etc.) if not, return
    if abdef.walkable or not abdef.buildable_to then return end
    -- check if walkable below to avoid throwing tools into abyss, return if not
    if not ufdef.walkable then return end
    -- check if a cane_plant or woody_plant and remove the node so that tool places properly
    if abdef.groups and (abdef.groups.woody_plant or abdef.groups.cane_plant) then
        minetest.set_node(above, {name = "air"})
    end
    -- check if should save meta
    local idata = {fields = {}}
    if idef.groups and (idef.groups.savemeta or idef.groups.craftedby) then
        local imeta = itemstack:get_meta()
        idata = imeta:to_table() or idata -- convert meta into table, otherwise go to premade table on failure
    end

    -- adds wear to meta
    local wear = itemstack:get_wear()
    -- remove if no wear at all (if it was present)
    -- NOTE: we need to convert to string before using meta:from_table, in newest luanti versions (5.13 + I think)
    idata.fields.wear = (wear ~= 0 and tostring(wear)) or nil

    -- take and place tool
    itemstack:take_item(1)
    local ppos = pointed_thing.above
    minetest.item_place_node(place_item, placer, pointed_thing)

    -- save to node meta
    local meta = minetest.get_meta(pointed_thing.above)
    meta:from_table(idata)

    -- name for debugging
    local pname = minetest.is_player(placer) and placer:get_player_name() or "non-player"
    minetest.log("action", pname.." placed "..placed_name.." at "..
                 ppos.x.."/"..ppos.y.."/"..ppos.z)
    return itemstack
end

local function on_dig_tool(pos, node, digger)
    local ndef = core.registered_nodes[node.name]
    -- get _tool or node's name subtract where "_placed" would be (8 from length)
    local tooldef = core.registered_items[ (ndef._tool or ndef.name:sub(1, -8)) ]
    if not tooldef then return end -- no definition, return
    local meta = core.get_meta(pos) -- we use meta for protection checking
    if minetest.is_protected(pos, digger, meta) then
        return -- can't dig tools you don't own
    end
    minimal.protection_on_dig(pos,node,digger,meta)
    -- get data from
    local ndata = meta:to_table()
    if not ndata then return end -- could not get data, return
    local player_inv = digger:get_inventory()
    local stack = ItemStack(tooldef.name)
    -- set wear from meta
    local wear = tonumber(ndata.fields.wear)
    if wear then
        stack:set_wear(wear)
        ndata.fields.wear = nil -- remove from fields
    end
    -- save node meta to item's meta if applicable (savemeta or craftedby in groups)
    if tooldef.groups and (tooldef.groups.savemeta or tooldef.groups.craftedby) then
        local imeta = stack:get_meta()
        imeta:from_table(ndata)
    end
    -- add to player's inventory, otherwise if inventory is full and  player has stop_on_inv_full off, drop as item
    if player_inv:room_for_item("main", stack) then
        minetest.remove_node(pos)
        player_inv:add_item("main", stack)
    elseif not minimal.stop_on_inv_full(digger) then
        minetest.add_item(pos, stack)
        minetest.remove_node(pos)
    end
end


-- Old versions
--[[ currently unused, old spots version, could be reused later----------------
-- opens the hammering spot GUI
local open_hammering_spot = crafting.make_on_rightclick(
    {"hammer", "hammer_mixing"}, 2, { x = 8, y = 3 })

-- opens the chopping spot GUI
local open_chopping_spot = {
    crafting.make_on_rightclick({"axe","knife_wattle","axe_mixing"},
        1, { x = 8, y = 3 }),
    crafting.make_on_rightclick({"axe","knife_wattle","axe_mixing"},
        2, { x = 8, y = 3 }),
}

--local open_knife = crafting.make_on_rightclick({"knife",'knife_wattle','knife_mixing'}, 2, { x = 8, y = 3 })

local open_digging_stick = {
    crafting.make_on_rightclick({"threshing_spot","soil_mixing",
                                 "shovel_agriculture"}, 1, { x = 8, y = 3 }),
    crafting.make_on_rightclick({"threshing_spot","soil_mixing",
                                 "shovel_agriculture"}, 2, { x = 8, y = 3 }),
}

-- checks if the node has one of the groups from good_on
local function is_spot_valid(node, good_on)
    for i in ipairs(good_on) do
        local group = good_on[i][1]
        local num = good_on[i][2]
        if minetest.get_item_group(node.name, group) == num then
            return true
        end
    end
    return false
end
    -- currently unused, replaced by crafting.crafting_item_on_rightclick
    -- in minetest.register_node()"tech:hammer_" .. mat .. "_placed", ..)
    -- opens the hammering spot GUI if the hammer is placed on a solid node
local function open_hammering_spot_if_valid(pos, node, clicker, itemstack,
                                            pointed_thing)
    local good_on = {{"stone", 1}, {"masonry", 1}, {"boulder", 1},
        {"soft_stone", 1}, {"tree", 1}, {"log", 1}}
    local pos_under = {x = pos.x, y = pos.y - 1, z = pos.z}
    local ground = minetest.get_node(pos_under)
    if is_spot_valid(ground, good_on) then
        open_hammering_spot(pos, node, clicker, itemstack, pointed_thing)
    else
        minetest.chat_send_player(
            clicker:get_player_name(),
            "Can't do hammering here! Needs: stone, masonry, tree, or a log.")
    end
end

    -- currently unused, replaced by crafting.crafting_item_on_rightclick
    -- in minetest.register_node("tech:adze_" .. material .. "_placed", ..)
    -- opens the chopping spot GUI if the hammer is placed on a solid node
local function open_chopping_spot_if_valid(pos, node, clicker, itemstack,
                                           pointed_thing, level)
    local good_on = {{"stone", 1}, {"masonry", 1}, {"soft_stone", 1},
        {"tree", 1}, {"log", 1}}
    local pos_under = {x = pos.x, y = pos.y - 1, z = pos.z}
    local ground = minetest.get_node(pos_under)
    if is_spot_valid(ground, good_on) then
        open_chopping_spot[level](pos, node, clicker, itemstack, pointed_thing)
    else
        minetest.chat_send_player(
            clicker:get_player_name(),
            "Can't chop here! Needs: stone, masonry, tree, or a log.")
    end
end
]]


-- Tools -----------------------------------------------------------------------

-- simple crafting, purely with bare hands
minetest.register_tool("tech:bare_hands",
        {
        description = S("Bare Hands"),
        inventory_image = "tech_bare_hands.png",
        exile_crafting = {
            craft_types  = {'hand', 'hand_tools', 'hand_pottery',
                             'hand_mixing', 'weaving_frame', 'threshing_spot'},
            craft_level  = 0,
            },
        groups = {not_in_creative_inventory = 1}
        })

-- crafting with bare hands on a solid base
minetest.register_tool("tech:hand",
        {
        description = S("Flat Surface"),
        inventory_image = "tech_flat_clear_surface.png",
        -- copied from tech:crafting_spot
        exile_crafting = {
            craft_types  = {'hand', 'hand_tools', 'hand_pottery',
                            'hand_mixing', 'weaving_frame', 'threshing_spot'},
            craft_level  = 2,
            },
        groups = {not_in_creative_inventory = 1}
        })

--1st level -- Crude emergency tools ------------------------------------------
--------------------------------------------------------------------------------

local hand_max_lvl = minimal.hand_max_lvl
local crude = 0.8
--local crude_use = base_use
local crude_max_lvl = hand_max_lvl

--damage
local crude_dmg = minimal.hand_dmg * 2
--snappy
local crude_snap3 = minimal.hand_snap * crude
local crude_snap2 = crude_snap3 * minimal.t_scale2
local crude_snap1 = crude_snap3 * minimal.t_scale1
--local crude_snap0 = 100 -- really long dig time - effectively disabled
--crumbly
local crude_crum3 = minimal.hand_crum * crude
local crude_crum2 = crude_crum3 * minimal.t_scale2
local crude_crum1 = crude_crum3 * minimal.t_scale1
local crude_crum0 = 100 -- really long dig time - effectively disabled
--choppy
local crude_chop3 = minimal.hand_chop * crude
local crude_chop2 = crude_chop3 * minimal.t_scale2
--local crude_chop0 = 100 -- really long dig time - effectively disabled
--cracky
--none at this level

-- Stone knife ----------------------------
--a crude chipped stone: 1.snap. 2. chop 3.crum

minetest.register_tool("tech:stone_chopper",
        {
        description = S("Stone Knife"),
        inventory_image = "tech_tool_stone_chopper.png",
        tool_capabilities = {
            full_punch_interval = base_punch_int,
            groupcaps={
                choppy = {times={[3]=crude_chop3}, uses=base_use*0.75,
                          maxlevel=crude_max_lvl},
                snappy= {times={[1]=crude_snap1, [2]=crude_snap2,
                             [3]=crude_snap3}, uses=base_use,
                         maxlevel=crude_max_lvl},
                crumbly = {times={[3]=crude_crum0}, uses=base_use*0.5,
                           maxlevel=crude_max_lvl}
            },
            damage_groups = {fleshy= crude_dmg},
        },
        groups = {knife = 1, craftedby = 1},
        _tool_placed = "tech:stone_knife_placed",
        _dig_tip = S("Cut plants faster than bare hands"),
        _use_tip = S("Flip to stone etcher"),
        _place_tip = S("Place tool for cutting crafts"),
        sound = {breaks = "tech_tool_breaks"},
        _on_use_item = function(player, wielded_item, pointed_thing)
            minimal.swap_tool(player, wielded_item, "tech:stone_etcher")
            return false
        end,
        on_place = function(itemstack, placer, pointed_thing)
            return place_tool(itemstack, placer, pointed_thing)
        end,
        }
    )

-- Placed stone knife
minetest.register_node("tech:stone_knife_placed",
        {
        description = S("Placed Stone Knife"),
        inventory_image = "tech_tool_stone_chopper.png",
        exile_crafting = {
            craft_types = {"knife",'knife_wattle','knife_mixing'},
            craft_level = 1,
        },
        drawtype = "mesh",
        mesh = "stone_knife_placed.obj",
        tiles = {name = "tech_stone_knife_placed.png"},
        paramtype = "light",
        paramtype2 = "facedir",
        sounds = nodes_nature.node_sound_stone_defaults(),
        groups = {dig_immediate = 3, temp_pass = 1, falling_node = 1,
                  not_in_creative_inventory = 1},
        selection_box = {
            type = "fixed",
            fixed = {-4/16, -8/16, -4/16, 4/16, -7/16, 4/16},
        },
        collision_box = {
            type = "fixed",
            fixed = {-4/16, -8/16, -4/16, 4/16, -7/16, 4/16},
        },
        _tool = "tech:stone_chopper", -- what tool to return we're dug
        on_rightclick = function(pos, node, clicker, itemstack, pointed_thing)
            return crafting.crafting_item_on_rightclick(pos,node,clicker,
                                                       itemstack,pointed_thing)
            --            open_knife(pos, node, clicker, itemstack, pointed_thing)
        end,
        on_dig = function(pos, node, digger)
            on_dig_tool(pos, node, digger)
        end,
        }
    )

-- craft stone chopper from gravel
crafting.register_recipe({
        type = {"crafting_spot","hand_tools"},
        output = "tech:stone_chopper 1",
        items = {"group:gravel"},
        level = 1,
        always_known = true,
        }
    )


-- Crumbly -----------------------------------

-- Soil tilling function

-- dirt particles
function dirt_particle(pos, node_name)
    return {
        amount = 10,
        time = 0.5,
        minpos = {x = pos.x - 0.5, y = pos.y - 0.50, z = pos.z - 0.5},
        maxpos = {x = pos.x + 0.5, y = pos.y, z = pos.z + 0.5},
        minvel = {x= -0.1, y= 2, z= -0.1},
        maxvel = {x= 0.1, y= 4, z= 0.1},
        minacc = {x= 0, y= -10, z= 0},
        maxacc = {x= 0, y= -10, z= 0},
        minexptime = 1.5,
        maxexptime = 1.5,
        minsize = 0.4,
        maxsize = 1,
        collisiondetection = true,
        vertical = false,
        node = {name = node_name, param2 = 0},
    }
end

local tilling = {} -- { pos = count } keeps track of soil currently being tilled
local function till_soil(player, wielded_item, pointed_thing)
    local toolname = wielded_item:get_name()
    local tillspeed = minetest.registered_tools[toolname]._till_speed
    if not tillspeed then
        error("till soil called from a tool with no till speed!")
    end
    if not pointed_thing or pointed_thing.type ~= "node" then return end
    local pos = pointed_thing.under
    local node = minetest.get_node(pos)
    local abovepos = vector.new(pos.x, pos.y + 1, pos.z)
    local above = minetest.get_node(abovepos)
    local posstr = minetest.pos_to_string(pos)
    if above.name ~= "air" then -- can't turn soil if there's something on top
        return
    end
    if minetest.get_item_group(node.name, "spreading") == 1 or
        minetest.get_item_group(node.name, "fertile_soil") >= 1 then
        local uses = wielded_item:get_tool_capabilities().groupcaps.tilling.uses
        if false or not (minimal.player_in_creative(player)) then
            wielded_item:add_wear(65535 / uses)
        end
        if not tilling[posstr] then
            tilling[posstr] = 0
            minetest.after(10, function(tpos) tilling[tpos] = nil end, posstr)
        end
        local particle = dirt_particle(abovepos, node.name)
        minetest.add_particlespawner(particle)
        minetest.sound_play("nodes_nature_dig_crumbly", {pos = pos, gain = 0.5})
        tilling[posstr] = tilling[posstr] + tillspeed
        if tilling[posstr] >= 10  then
            soil.till(wielded_item, player, pointed_thing)
        end
        return false -- don't update the wielded item after the call
    end
end

-- digging stick ---------------------------------------
--specialist for digging. Can also till

minetest.register_tool("tech:digging_stick",
        {
        description = S("Digging Stick"),
        inventory_image = "tech_tool_digging_stick.png^[transformR90",
        tool_capabilities = {
            full_punch_interval = base_punch_int*1.1,
            groupcaps={
                crumbly = {times= {[1]=crude_crum1, [2]=crude_crum2,
                               [3]=crude_crum3}, uses=base_use,
                           maxlevel=crude_max_lvl},
                tilling = {uses = base_use},
            },
            damage_groups = {fleshy= crude_dmg},
        },
        groups = {shovel = 1, craftedby = 1, hoe = 1},
        sound = {breaks = "tech_tool_breaks"},
        _till_speed = 3,
        _dig_tip = S("Dig hard earth"),
        _use_tip = S("Till soil slowly"),
        _on_use_item = till_soil,
        _place_tip = S("Place tool for farming crafts"),
        on_place = function(itemstack, placer, pointed_thing)
            return place_tool(itemstack, placer, pointed_thing)
        end,
        }
    )

-- Placed digging stick
minetest.register_node("tech:digging_stick_placed",
        {
        description = S("Placed Digging Stick"),
        inventory_image = "tech_tool_digging_stick.png^[transformR90",
        exile_crafting = {
            craft_types = {"threshing_spot","soil_mixing", "shovel_agriculture"},
            craft_level = 1,
        },
        drawtype = "mesh",
        mesh = "digging_stick_placed.obj",
        tiles = {name = "tech_axe_iron_placed.png"}, -- reuses the texture to save space
        paramtype = "light",
        paramtype2 = "facedir",
        sounds = nodes_nature.node_sound_stone_defaults(),
        groups = {dig_immediate = 3, temp_pass = 1, falling_node = 1,
                  not_in_creative_inventory = 1},
        use_texture_alpha = c_alpha.clip,
        node_box = {
            type = "fixed",
            fixed = {-0.5, -0.5, -0.5, 0.5, -0.45, 0.5},
        },
        selection_box = {
            type = "fixed",
            fixed = {-0.5, -0.5, -0.5, 0.5, -0.25, 0.5},
        },
        on_rightclick = function(pos, node, clicker, itemstack, pointed_thing)
            return crafting.crafting_item_on_rightclick(pos,node,clicker,
                                                       itemstack,pointed_thing)
            --            open_digging_stick[1](pos, node, clicker, itemstack, pointed_thing)
        end,
        on_dig = function(pos, node, digger)
            on_dig_tool(pos, node, digger)
        end,
        }
    )

----digging stick from sticks
crafting.register_recipe({
        type = {"crafting_spot","hand_tools","knife"},
        output = "tech:digging_stick 1",
        items = {"tech:stick 2"},
        level = 0,
        always_known = true,
    }
)

--2nd level -- polished stone tools. Sophisticated stone age tools ------------
--------------------------------------------------------------------------------
--[[
    note: we have multiple rock types
    Granite is harder than basalt.
]]--

local stone = 0.8
local stone_use = base_use * 2
local stone_max_lvl = hand_max_lvl

--damage
local stone_dmg = crude_dmg * 2
--snappy
local stone_snap3 = crude_snap3 * stone
local stone_snap2 = crude_snap2 * stone
local stone_snap1 = crude_snap1 * stone
--crumbly
local stone_crum3 = crude_crum3 * stone
local stone_crum2 = crude_crum2 * stone
local stone_crum1 = crude_crum1 * stone
--choppy
local stone_chop3 = crude_chop3 * stone
local stone_chop2 = crude_chop2 * stone
--cracky
--none at this level


-- Adzes ---------------------------------------------------
-- suffix/material, definition
-- registers tool, placed, and recipe
local function register_adze(suffix, def)
    -- tool string
    local name = "tech:adze_"..suffix
    -- tool durability
    local uses = def.uses or {}
    def.uses = nil -- remove from definition
    uses.choppy = uses.choppy or 1
    uses.snappy = uses.snappy or 1
    uses.crumbly = uses.crumbly or 1
    -- register tool
    minetest.register_tool(
        name, {
            description = S("@1 Adze", def.description),
            inventory_image = "tech_tool_adze_" .. suffix .. ".png",
            tool_capabilities = {
                full_punch_interval = base_punch_int * 1.1,
                groupcaps={
                    choppy = {times={[2]=stone_chop2, [3]=stone_chop3},
                      uses=stone_use * uses.choppy,
                      maxlevel=stone_max_lvl},
                    snappy= {times={[1]=stone_snap1, [2]=stone_snap2,
                      [3]=stone_snap3},
                      uses=stone_use * uses.snappy,
                      maxlevel=stone_max_lvl},
                    crumbly = {times={[3]=crude_crum3},
                      uses=base_use*uses.crumbly,
                      maxlevel=crude_max_lvl},
                },
                damage_groups = {fleshy = stone_dmg},
            },
            groups = {axe = 1, craftedby = 1},
            sound = {breaks = "tech_tool_breaks"},
            _dig_tip = S("Cut softwood logs"),
            _place_tip = S("Place tool for woodworking crafts"),
            on_place = function(itemstack, placer, pointed_thing)
                return place_tool(itemstack, placer, pointed_thing)
            end,
    })
    -- register placed
    minetest.register_node(
        name.."_placed", {
            description = S("Placed @1 adze", def.description),
            inventory_image = "tech_tool_adze_"..suffix..".png",
            exile_crafting = {
                craft_types = {"axe","knife_wattle","axe_mixing"},
                craft_level = 1,
                good_on = {
                    {"stone", 1}, {"masonry", 1}, {"soft_stone", 1},
                    {"tree", 1}, {"log", 1}
                },
            },
            drawtype = "mesh",
            mesh = "adze_placed.obj",
            tiles = {name = "tech_adze_" .. suffix .. "_placed.png"},
            paramtype = "light",
            paramtype2 = "facedir",
            sounds = nodes_nature.node_sound_stone_defaults(),
            groups = {dig_immediate = 3, temp_pass = 1,
            falling_node = 1, not_in_creative_inventory = 1},
            use_texture_alpha = c_alpha.clip,
            node_box = {
                type = "fixed",
                fixed = {-0.5, -0.5, -0.5, 0.5, -0.45, 0.5},
            },
            selection_box = {
                type = "fixed",
                fixed = {-0.5, -0.5, -0.5, 0.5, -0.25, 0.5},
            },
            on_rightclick = function(pos, node, clicker,
                itemstack, pointed_thing)
                return crafting.crafting_item_on_rightclick(pos,node,
                clicker,itemstack,
                pointed_thing)
            end,
            on_dig = function(pos, node, digger)
                on_dig_tool(pos, node, digger)
            end,
    })
    -- recipe
    crafting.register_recipe({
        type = {"hand_tools", "grinding_stone" },
        output = name,
        items = {"group:" .. suffix .."_cobble",'tech:stick',
                 'group:fibrous_plant 4'},
        level = 1,
        always_known = true,
        tool = "nodes_nature:sand"
    })
end
-- less uses than granite bc softer stone
register_adze("basalt", {
    description = S("Basalt"),
    uses = {choppy = 0.9, snappy = 0.7, crumbly = 0.9}
})
-- more uses than granite
register_adze("jade", {
    description = S("Jade"),
    uses = {choppy = 1.5}
})
-- best for chopping
register_adze("granite", {
    description = S("Granite"),
    uses = {snappy = 0.8}
})


--IB-20240226 --grind adze
--IB-20240226 crafting.register_recipe({
--IB-20240226   type = "grinding_stone",
--IB-20240226   output = "tech:adze_granite",
--IB-20240226   items = {"group:granite_cobble", 'tech:stick', 'group:fibrous_plant 4', 'nodes_nature:sand'},
--IB-20240226   level = 1,
--IB-20240226   always_known = true,
--IB-20240226 })
--
--IB-20240226 crafting.register_recipe({
--IB-20240226   type = "grinding_stone",
--IB-20240226   output = "tech:adze_basalt",
--IB-20240226   items = {"group:basalt_cobble", 'tech:stick', 'group:fibrous_plant 4', 'nodes_nature:sand'},
--IB-20240226   level = 1,
--IB-20240226   always_known = true,
--IB-20240226 })

-- Hammers -------------------------------------------------
-- suffix/material, description
-- registers tool, placed, and recipe
-- can act as a weak weapon and stun animals
local function register_hammer(suffix, desc)
    -- register tool
    local name = "tech:hammer_"..suffix -- used in tool registration, placed, and recipe
    minetest.register_tool(
    name, {
        description = S("@1 Hammer", desc),
        inventory_image = "tech_tool_hammer_" .. suffix .. ".png",
        tool_capabilities = {
            full_punch_interval = base_punch_int * 1.2,
            groupcaps={
                choppy = {times={[3]=crude_chop3},
                uses=base_use*0.5, maxlevel=crude_max_lvl},
                snappy = {times={[3]=crude_snap3},
                uses=base_use*0.5, maxlevel=crude_max_lvl},
                crumbly = {times= {[3]=crude_crum3},
                uses=base_use*0.5, maxlevel=crude_max_lvl}
            },
            damage_groups = {fleshy=stone_dmg + 1},
            -- +1 was added in new default hammer, legacy one had only stone_dmg
        },
        _dig_tip = S("Strike") .. " / " .. S("Stun animals"),
        -- NOTE: don't put "\n" in the translation here,
        -- because then, it will fail once inside a "core.colorize" function.
        -- it works with core.get_color_escape_sequence(color)
        -- then text (even with \n)
        -- then core.get_color_escape_sequence(white)
        -- so we changed it in minimaltooltips.lua already
        -- but in case someone wants to put colorize again,
        -- I changed it here too
        -- please leave that comment so that next one doesn't loose time discovering again this behavior
        --[[
        _place_tip = S("Stun animals\n"..
        " or Place on solid surface for hammering crafts"),
        --]]
        _place_tip = S("Place tool for hammering crafts"),
        on_place = function(itemstack, placer, pointed_thing)
            return place_tool(itemstack, placer, pointed_thing)
        end,
        groups = {club = 1, craftedby = 1},
        sound = {breaks = "tech_tool_breaks"},
    })
    -- register placed
    minetest.register_node(
        name.."_placed", {
            description = S("Placed @1 Hammer", desc),
        inventory_image = "tech_tool_hammer_" .. suffix .. ".png",
        exile_crafting = {
            craft_types = {"hammer", "hammer_mixing"},
            craft_level = 1,
            material = suffix,
            good_on = {
                {"stone", 1}, {"masonry", 1},
                {"boulder", 1}, {"soft_stone", 1},
                {"tree", 1}, {"log", 1}
            },
        },
        drawtype = "mesh",
        mesh = "hammer_placed.obj",
        tiles = {name = "tech_hammer_" .. suffix .. "_placed.png"},
        paramtype = "light",
        paramtype2 = "facedir",
        sounds = nodes_nature.node_sound_stone_defaults(),
        groups = {dig_immediate = 3, temp_pass = 1,
        falling_node = 1, not_in_creative_inventory = 1},
        use_texture_alpha = c_alpha.clip,
        node_box = {
            type = "fixed",
            fixed = {-0.5, -0.5, -0.5, 0.5, -0.45, 0.5},
        },
        selection_box = {
            type = "fixed",
            fixed = {-0.5, -0.5, -0.5, 0.5, -0.25, 0.5},
        },
        on_rightclick = function(pos, node, clicker,
            itemstack, pointed_thing)
            return crafting.crafting_item_on_rightclick(pos,node,
            clicker,itemstack,
            pointed_thing)
        end,
        on_dig = function(pos, node, digger)
            on_dig_tool(pos, node, digger)
        end,
    })
    -- register recipe
    crafting.register_recipe({
        type = { "hand_tools", "grinding_stone" },
        output = name,
        items = {"group:" .. suffix .."_cobble", 'tech:stick',
        'group:fibrous_plant 4'},
        level = 1,
        always_known = true,
        tool = "nodes_nature:sand"
    })
end
-- basalt and granite hammer
register_hammer("basalt", S("Basalt"))
register_hammer("granite", S("Granite"))


--Stone club -----------------------------------------------
-- A weapon. Not very good for anything else
-- can stun animals
minetest.register_tool("tech:stone_club",
        {
        description = S("Stone Club"),
        inventory_image = "tech_tool_stone_club.png",
        tool_capabilities = {
            full_punch_interval = base_punch_int * 1.2,
            groupcaps={
                choppy = {times={[3]=crude_chop3}, uses=base_use*0.5,
                          maxlevel=crude_max_lvl},
                snappy = {times={[3]=crude_snap3}, uses=base_use*0.5,
                          maxlevel=crude_max_lvl},
                crumbly = {times= {[3]=crude_crum3}, uses=base_use*0.5,
                           maxlevel=crude_max_lvl}
            },
            damage_groups = {fleshy=stone_dmg*2},
        },
        _dig_tip = S("Strike") .. " / " .. S("Stun animals"),
        groups = {club = 1, craftedby = 1},
        sound = {breaks = "tech_tool_breaks"},
        }
    )

crafting.register_recipe({
        type = { "hand_tools", "grinding_stone" },
        output = "tech:stone_club",
        items = {"group:granite_cobble"},
        level = 1,
        always_known = true,
        tool = "nodes_nature:sand"
        }
    )


--3rd level - iron tools. -----------------------------------------------------
--------------------------------------------------------------------------------

local iron = 0.9
local iron_use = base_use * 4
local iron_max_lvl = hand_max_lvl + 1

--damage
local iron_dmg = stone_dmg * 2
--snappy
local iron_snap3 = stone_snap3 * iron
local iron_snap2 = stone_snap2 * iron
local iron_snap1 = stone_snap1 * iron
--crumbly
local iron_crum3 = stone_crum3 * iron
local iron_crum2 = stone_crum2 * iron
local iron_crum1 = stone_crum1 * iron
--choppy
local iron_chop3 = stone_chop3 * iron
local iron_chop2 = stone_chop2 * iron
local iron_chop1 = (minimal.hand_chop * minimal.t_scale1) * crude * stone * iron
--cracky
local iron_crac3 = minimal.hand_crac * crude * stone * iron
local iron_crac2 = (minimal.hand_crac * minimal.t_scale2) * crude * stone * iron
--local iron_crac1 = (minimal.hand_crac * minimal.t_scale1) * crude * stone * iron

-- Axe ----------------------------------------------------

--Axe. best for chopping, snappy
minetest.register_tool("tech:axe_iron",
        {
        description = S("Iron Axe"),
        inventory_image = "tech_tool_axe_iron.png",
        tool_capabilities = {
            full_punch_interval = base_punch_int * 1.1,
            groupcaps={
                choppy = {times={[1]=iron_chop1, [2]=iron_chop2,
                              [3]=iron_chop3}, uses=iron_use,
                          maxlevel=iron_max_lvl},
                snappy = {times={[1]=iron_snap1, [2]=iron_snap2,
                              [3]=iron_snap3}, uses=iron_use,
                          maxlevel=iron_max_lvl},
                crumbly = {times={[3]=crude_crum3}, uses= stone_use,
                           maxlevel=stone_max_lvl},
            },
            damage_groups = {fleshy = iron_dmg},
        },
        _dig_tip = S("Cut any wood"),
        _place_tip = S("Place tool for woodworking crafts"),
        groups = {axe = 1, craftedby = 1},
        sound = {breaks = "tech_tool_breaks"},
        on_place = function(itemstack, placer, pointed_thing)
            return place_tool(itemstack, placer, pointed_thing)
        end,
        }
    )

-- Placed iron axe
minetest.register_node("tech:axe_iron_placed",
        {
        description = S("Placed Iron Axe"),
        inventory_image = "tech_tool_axe_iron.png",
        exile_crafting = {
            craft_types = {"axe","knife_wattle","axe_mixing"},
            craft_level = 2,
            good_on = {
                {"stone", 1}, {"masonry", 1}, {"soft_stone", 1},
                {"tree", 1}, {"log", 1}
            },
        },
        drawtype = "mesh",
        mesh = "axe_placed.obj",
        tiles = {name = "tech_axe_iron_placed.png"},
        paramtype = "light",
        paramtype2 = "facedir",
        sounds = tech.node_sound_metal_defaults(),
        groups = {dig_immediate = 3, temp_pass = 1,
                  falling_node = 1, not_in_creative_inventory = 1},
        use_texture_alpha = c_alpha.clip,
        node_box = {
            type = "fixed",
            fixed = {-0.5, -0.5, -0.5, 0.5, -0.45, 0.5},
        },
        selection_box = {
            type = "fixed",
            fixed = {-0.5, -0.5, -0.5, 0.5, -0.25, 0.5},
        },
        on_rightclick = function(pos, node, clicker, itemstack, pointed_thing)
            return crafting.crafting_item_on_rightclick(pos,node,clicker,
                                                       itemstack,pointed_thing)
        end,
        on_dig = function(pos, node, digger)
            on_dig_tool(pos, node, digger)
        end,
        }
    )

-- Register "tech:axe_iron" recipe
crafting.register_recipe({
    type = "anvil",
    output = "tech:axe_iron",
    items = {'tech:iron_ingot', 'tech:stick'},
    level = 1,
    always_known = true,
})

-- Shovel -------------------------------------------------

-- shovel... best for digging. Can also till
minetest.register_tool("tech:shovel_iron",
        {
        description = S("Iron Shovel"),
        inventory_image = "tech_tool_shovel_iron.png^[transformR90",
        tool_capabilities = {
            full_punch_interval = base_punch_int*1.1,
            groupcaps={
                crumbly = {times= {[1]=iron_crum1, [2]=iron_crum2,
                               [3]=iron_crum3}, uses=iron_use,
                           maxlevel=iron_max_lvl},
                snappy = {times= {[3]=stone_snap3}, uses=iron_use * 0.8,
                          maxlevel=iron_max_lvl},
                tilling = {uses = iron_use * 0.8}, -- not too good for tilling
            },
            damage_groups = {fleshy= iron_dmg * 0.75},
        },
        groups = {shovel = 1, craftedby = 1, hoe = 1},
        sound = {breaks = "tech_tool_breaks"},
        _dig_tip = S("Dig earth quickly"),
        _till_speed = 4,
        _on_use_item = till_soil,
        _use_tip = S("Till soil"),
        _place_tip = S("Place tool for farming crafts"),
        on_place = function(itemstack, placer, pointed_thing)
            return place_tool(itemstack, placer, pointed_thing)
        end,
        }
    )

-- Placed iron shovel
minetest.register_node("tech:shovel_iron_placed",
        {
        description = S("Placed Iron Shovel"),
        inventory_image = "tech_tool_shovel_iron.png^[transformR90",
        exile_crafting = {
            craft_types = {"threshing_spot","soil_mixing", "shovel_agriculture"},
            craft_level = 1,
        },
        drawtype = "mesh",
        mesh = "shovel_placed.obj",
        tiles = {name = "tech_axe_iron_placed.png"},
        paramtype = "light",
        paramtype2 = "facedir",
        sounds = tech.node_sound_metal_defaults(),
        groups = {dig_immediate = 3, temp_pass = 1,
                  falling_node = 1, not_in_creative_inventory = 1},
        use_texture_alpha = c_alpha.clip,
        node_box = {
            type = "fixed",
            fixed = {-0.5, -0.5, -0.5, 0.5, -0.45, 0.5},
        },
        selection_box = {
            type = "fixed",
            fixed = {-0.5, -0.5, -0.5, 0.5, -0.25, 0.5},
        },
        on_rightclick = function(pos, node, clicker, itemstack, pointed_thing)
            return crafting.crafting_item_on_rightclick(pos,node,clicker,
                                                       itemstack,pointed_thing)
            --            open_digging_stick[1](pos, node, clicker, itemstack, pointed_thing)
        end,
        on_dig = function(pos, node, digger)
            on_dig_tool(pos, node, digger)
        end,
        }
    )

crafting.register_recipe({
        type = "anvil",
        output = "tech:shovel_iron",
        items = {'tech:iron_ingot', 'tech:stick'},
        level = 1,
        always_known = true,
        }
    )

-- Mace ---------------------------------------------------
-- A weapon. Not very good for anything else
-- can stun animals

minetest.register_tool("tech:mace_iron",
        {
        description = S("Iron Mace"),
        inventory_image = "tech_tool_mace_iron.png",
        tool_capabilities = {
            full_punch_interval = base_punch_int * 1.2,
            groupcaps={
                choppy = {times={[3]=crude_chop3}, uses=base_use*0.5,
                          maxlevel=crude_max_lvl},
                snappy = {times={[3]=crude_snap3}, uses=base_use*0.5,
                          maxlevel=crude_max_lvl},
                crumbly = {times= {[3]=crude_crum3}, uses=base_use*0.5,
                           maxlevel=crude_max_lvl},
            },
            damage_groups = {fleshy=iron_dmg*2},
        },
        groups = {club = 1, craftedby = 1},
        sound = {breaks = "tech_tool_breaks"},
        _dig_tip = S("Strike") .. " / " .. S("Stun animals"),
        }
    )

crafting.register_recipe({
        type = "anvil",
        output = "tech:mace_iron",
        items = {'tech:iron_ingot 2'},
        level = 1,
        always_known = true,
        }
    )

-- -Pick Axe ----------------------------------------------
-- mining, digging

minetest.register_tool("tech:pickaxe_iron",
        {
        description = S("Iron Pickaxe"),
        inventory_image = "tech_tool_pickaxe_iron.png",
        tool_capabilities = {
            full_punch_interval = base_punch_int * 1.1,
            groupcaps={
                choppy = {times={[3]=stone_chop3}, uses=iron_use *0.8,
                          maxlevel=iron_max_lvl},
                snappy = {times={[3]=stone_snap3}, uses=iron_use *0.8,
                          maxlevel=iron_max_lvl},
                crumbly = {times={[1]=stone_crum1, [2]=stone_crum2,
                               [3]=stone_crum3}, uses= iron_use,
                           maxlevel=iron_max_lvl},
                cracky = {times= {[2]=iron_crac2, [3]=iron_crac3},
                          uses=iron_use, maxlevel=iron_max_lvl},
            },
            damage_groups = {fleshy = iron_dmg},
        },
        _dig_tip = S("Dig stone"),
        _place_tip = S("Place tool for hammering crafts"),
        groups = {pickaxe = 1, craftedby = 1},
        sound = {breaks = "tech_tool_breaks"},
        on_place = function(itemstack, placer, pointed_thing)
            return place_tool(itemstack, placer, pointed_thing)
        end,
        }
    )

minetest.register_node("tech:pickaxe_iron_placed",
        {
        description = S("Placed Iron Pickaxe"),
        inventory_image = "tech_tool_pickaxe_iron.png",
        exile_crafting = {
            craft_types = {"hammer", "hammer_mixing"},
            craft_level = 1,
            material = suffix,
            good_on = {
                {"stone", 1}, {"masonry", 1},
                {"boulder", 1}, {"soft_stone", 1},
                {"tree", 1}, {"log", 1}
            },
        },
        drawtype = "mesh",
        mesh = "pickaxe_placed.obj",
        tiles = {name = "tech_axe_iron_placed.png"},
        paramtype = "light",
        paramtype2 = "facedir",
        sounds = tech.node_sound_metal_defaults(),
        groups = {dig_immediate = 3, temp_pass = 1,
                  falling_node = 1, not_in_creative_inventory = 1},
        use_texture_alpha = c_alpha.clip,
        node_box = {
            type = "fixed",
            fixed = {-0.5, -0.5, -0.5, 0.5, -0.45, 0.5},
        },
        selection_box = {
            type = "fixed",
            fixed = {-0.5, -0.5, -0.5, 0.5, -0.25, 0.5},
        },
        on_rightclick = function(pos, node, clicker, itemstack, pointed_thing)
            return crafting.crafting_item_on_rightclick(pos,node,clicker,
                                                       itemstack,pointed_thing)
        end,
        on_dig = function(pos, node, digger)
            on_dig_tool(pos, node, digger)
        end,
        }
    )

crafting.register_recipe({
        type = "anvil",
        output = "tech:pickaxe_iron",
        items = {'tech:iron_ingot 2', 'tech:stick'},
        level = 1,
        always_known = true,
        }
    )

-- Iron Hoe ----------------------------------------------

minetest.register_tool("tech:hoe_iron",
        {
        description = S("Iron Hoe"),
        inventory_image = "tech_tool_hoe_iron.png",
        tool_capabilities = {
            full_punch_interval = base_punch_int,
            groupcaps={
                crumbly = {times= {[1]=crude_crum1, [2]=crude_crum2,
                               [3]=crude_crum3},
                           uses=base_use, maxlevel=crude_max_lvl},
                tilling = {uses = iron_use},
            },
            damage_groups = {fleshy = iron_dmg * 0.75},
        },
        groups = {hoe = 1, craftedby = 1},
        sound = {breaks = "tech_tool_breaks"},
        _till_speed = 5,
        _dig_tip = S("Dig hard earth"),
        _use_tip = S("Till soil quickly"),
        _on_use_item = till_soil,
        _place_tip = S("Place tool for farming crafts"),
        on_place = function(itemstack, placer, pointed_thing)
            return place_tool(itemstack, placer, pointed_thing)
        end,
        }
    )

minetest.register_node("tech:hoe_iron_placed",
        {
        description = S("Placed Iron Hoe"),
        inventory_image = "tech_tool_hoe_iron.png",
        exile_crafting = {
            craft_types = {"threshing_spot","soil_mixing", "shovel_agriculture"},
            craft_level = 1,
        },
        drawtype = "mesh",
        mesh = "hoe_placed.obj",
        tiles = {name = "tech_axe_iron_placed.png"},
        paramtype = "light",
        paramtype2 = "facedir",
        sounds = tech.node_sound_metal_defaults(),
        groups = {dig_immediate = 3, temp_pass = 1,
                  falling_node = 1, not_in_creative_inventory = 1},
        use_texture_alpha = c_alpha.clip,
        node_box = {
            type = "fixed",
            fixed = {-0.5, -0.5, -0.5, 0.5, -0.45, 0.5},
        },
        selection_box = {
            type = "fixed",
            fixed = {-0.5, -0.5, -0.5, 0.5, -0.25, 0.5},
        },
        on_rightclick = function(pos, node, clicker, itemstack, pointed_thing)
            return crafting.crafting_item_on_rightclick(pos,node,clicker,
                                                       itemstack,pointed_thing)
            --            open_digging_stick[1](pos, node, clicker, itemstack, pointed_thing)
        end,
        on_dig = function(pos, node, digger)
            on_dig_tool(pos, node, digger)
        end,
        }
    )

crafting.register_recipe({
        type = "anvil",
        output = "tech:hoe_iron",
        items = {'tech:iron_ingot', 'tech:stick'},
        level = 1,
        always_known = true,
        }
    )

-- Others ----------------------------------------------------------------------
--[[
    --would be nice to have,
    --but hard to do without either spamming with crafts,
    --or having illogical mass balance (e.g. anvil = 1 ingot and axe = 1 ingot)
    crafting.register_recipe({
    type = "anvil",
    output = "tech:iron_ingot",
    items = {'group:iron 2'},
    level = 1,
    always_known = true,
    })
]]
