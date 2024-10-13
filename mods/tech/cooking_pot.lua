----------------------------------------------------------
--COOKING POT



----------------------------------------------------------
--[[
    Food capacity

    Display:
    Food %
    Cooking progress %

    Click with food item to add to pot -> ^food vProgress

    Heat to cook

    Click with hand to eat -> vFood %


    Save to inv meta

]]

-- Internationalization
local S = tech.S

minimal = minimal

local random = math.random

local cook_time = 1
local cook_temp = { [""] = 101, ["Soup"] = 100 }
local portions = 10 -- TODO: is this sane? Can we adjust it based on contents?


---------------------
local pot_box = {
    {-0.375, -0.1875, -0.375, 0.375, -0.0625, 0.375}, -- NodeBox1
    {-0.3125, -0.3125, -0.3125, 0.3125, -0.1875, 0.3125}, -- NodeBox2
    {-0.25, -0.4375, -0.25, 0.25, -0.3125, 0.25}, -- NodeBox3
    {-0.3125, -0.0625, -0.3125, 0.3125, 0, 0.3125}, -- NodeBox4
    {-0.25, 0, -0.25, 0.25, 0.0625, 0.25}, -- NodeBox5
    {-0.125, 0.0625, -0.0625, -0.0625, 0.1875, 0.0625}, -- NodeBox6
    {0.0625, 0.0625, -0.0625, 0.125, 0.1875, 0.0625}, -- NodeBox7
    {-0.0625, 0.125, -0.0625, 0.0625, 0.1875, 0.0625}, -- NodeBox8
    {0.25, -0.4375, 0.25, 0.375, -0.3125, 0.375}, -- NodeBox9
    {0.25, -0.5, 0.25, 0.4375, -0.4375, 0.4375}, -- NodeBox10
    {0.25, -0.5, -0.4375, 0.4375, -0.4375, -0.25}, -- NodeBox11
    {-0.4375, -0.5, -0.4375, -0.25, -0.4375, -0.25}, -- NodeBox12
    {-0.4375, -0.5, 0.25, -0.25, -0.4375, 0.4375}, -- NodeBox13
    {0.25, -0.4375, -0.375, 0.375, -0.3125, -0.25}, -- NodeBox14
    {-0.375, -0.4375, -0.375, -0.25, -0.3125, -0.25}, -- NodeBox15
    {-0.375, -0.4375, 0.25, -0.25, -0.3125, 0.375}, -- NodeBox16
    {-0.4375, -0.0625, -0.0625, -0.3125, 0.0625, 0.0625}, -- NodeBox23
    {0.3125, -0.0625, -0.0625, 0.4375, 0.0625, 0.0625}, -- NodeBox24
}

local pot_formspec = "size[8,4.1]"..
    "list[current_name;main;0,0;8,2]"..
    "list[current_player;main;0,2.3;8,4]"..
    "listring[current_name;main]"..
    "listring[current_player;main]"

minetest.register_craftitem("tech:soup", {
                                description = S("Soup"),
                                inventory_image = "tech_soup.png",
                                stack_max = minimal.stack_max_medium,
                                groups = { edible = 2 },
                                _use_tip = S("Eat"),
})

local function clear_pot(pos)
    local meta = minetest.get_meta(pos)
    meta:set_string("formspec", "")
    meta:set_string("type", "")
    meta:set_string("status", "") -- "" = unprepared, "Cooking", "Finished"
    meta:set_string("status_string","")
    meta:set_string("contents_string","")
    meta:set_string("note","")
    minimal.infotext_set_new(pos, meta)
    local inv = meta:get_inventory()
    inv:set_size("main", 8)
end

local function pot_rightclick(pos, node, clicker, itemstack, pointed_thing)
    local timer = minetest.get_node_timer(pos)
    -- restart timer if there's issues
    if timer:is_started() then return end
    -- timer is dead, check status
    local meta = minetest.get_meta(pos)
    local status = meta:get_string("status")
    if status == "" then return end -- no issues, pot hasn't started
    timer:start(6) -- timer died somehow? restart it here
end

local function pot_receive_fields(pos, formname, fields, sender)
    local meta = minetest.get_meta(pos)
    local inv = meta:get_inventory():get_list("main")
    if not inv then -- This is a bugged pot from before commit 851e0ec744
        meta:get_inventory():set_size("main", 8) -- So, fix it
        inv = meta:get_inventory():get_list("main")
    end
    local total = {hp=0,th=0,hu=0,en=0}
    if meta:get_string("status") == "finished" then -- reset the pot for next cook
        if meta:get_inventory():is_empty("main") then
            clear_pot(pos)
        end
        return
    end
    local contents="" -- String containing list of pot contents
    if meta:get_string('type') == 'Soup' then
        contents=S("Water, ")
    end
    for i = 1, #inv do
        local result = HEALTH.get_food_stats(inv[i],true) -- second parameter: prefer cooked, raw if none
        if result then
            local count = inv[i]:get_count()
            for stat,value in pairs(result) do
                if total[stat] then -- prevent temp from being changed lol
                    total[stat] = total[stat] + (value * count)
                end
            end
            contents = contents..inv[i]:get_short_description()..", "
        end
    end
    contents=contents:sub(1, #contents - 2) -- take last ', ' from contents
    -- for infotext
    meta:set_string("contents_string",S("Contents: @1",contents))
    meta:set_string("note","nil") -- clear note about adding food
    minimal.infotext_set_new(pos, meta)

    local length = meta:get_int("baking")
    if length <= (cook_time - 4) then
        length = length + 4 -- don't open a cooking pot, you'll let the heat out
        --TODO: Can we drain current temp while the formspec's open? Groups?
        meta:set_int("baking", length)
    end
    meta:set_string("pot_contents", minetest.serialize(total))
end

local function divide_portions(total)
    local result = total
    for stat,value in pairs(result) do
        if type(value) == "number" then
            result[stat] = (value / portions)
        end
    end
    return result
end

-- spawn steam particles
-- pos, amount, timedelay
local function spawn_steam(pos,def)
    local ndef = minimal.get_nodedef(pos)
    -- utilize collision box for proper node interactions
    local collbox = ndef.collision_box or {-0.5,-0.5,-0.5, 0.5,0.5,0.5}
    def = def or {}
    def.amount = def.amount or def.amt or random(6,10)
    if type(def.amount) == "table" then -- randomize
        def.amount = random(def.amount[1],def.amount[2])
    end
    def.animation = {
        type = "vertical_frames",
        aspect_w = 16,
        aspect_h = 16,
        length = 1.1, -- 11 frames, 0.1s/ea
    }
    def.time = def.time or 7 -- a second more than the node timer
    def.glow = def.glow or 4
    def.minsize = def.minsize or 10
    def.maxsize = def.maxsize or 10
    def.collisiondetection = true
    def.vertical = true
    def.minexptime = def.minexptime or 1
    def.maxexptime = def.maxexptime or 1
    -- is iterated through for variations
    local spawnpos = {
        {
            x = (pos.x + collbox[1]),
            vel = {x={0.2,0.7}}
        },
        {
            x = (pos.x + collbox[4]),
            vel = {x={-0.2,-0.7}}
        },
        {
            z = (pos.z + collbox[3]),
            vel = {z={0.2,0.7}}
        },
        {
            z = (pos.z + collbox[6]),
            vel = {z={-0.2,-0.7}}
        }
    }
    local denied = 0 -- utilized to determine how many spawnpos variants are ignored
    for i,spinfo in pairs(spawnpos) do
        def.texture = "tech_steam_particles.png^[opacity:"..random(160,255)
        -- allow particle pos customization with spawnpos
        local ppos = {x=(spinfo.x or pos.x),y=(pos.y+collbox[5]),z=(spinfo.z or pos.z)}
        ppos.x = {ppos.x-0.1,ppos.x+0.1}
        ppos.y = {ppos.y-0.3,ppos.y+0.1}
        ppos.z = {ppos.z-0.1,ppos.z+0.1}
        local vel = spinfo.vel
        if denied > 2 or random() >= 0.5 then -- if more than 2 ignored variants or if 50%
            -- get or create min-max velocity system
            vel.x = vel.x or {0,0}
            vel.y = vel.y or {0.2,1}
            vel.z = vel.z or {0,0}
            -- set raw values
            def.minpos = {x=ppos.x[1],y=ppos.y[1],z=ppos.z[1]}
            def.maxpos = {x=ppos.x[2],y=ppos.y[2],z=ppos.z[2]}
            def.minvel = {x=vel.x[1],y=vel.y[1],z=vel.z[1]}
            def.maxvel = {x=vel.x[2],y=vel.y[2],z=vel.z[2]}
            minetest.add_particlespawner(def)
        else -- add to denied
            denied = denied + 1
        end
    end
end

local function pot_cook(pos, elapsed)
    local meta = minetest.get_meta(pos)
    local inv = meta:get_inventory():get_list("main")
    local total = ( minetest.deserialize(meta:get_string("pot_contents")) or
                    {hp=0,th=0,hu=0,en=0 } )
    total.th = total.th or 0
    local kind = meta:get_string("type")
    climate.heat_transfer(pos, "tech:cooking_pot")
    local temp = climate.get_point_temp(pos)
    local baking = meta:get_int("baking")
    local status = meta:get_string("status")
    if status == "finished" then
        -- Handle burning food here
        --TODO: burned: reduce the value of pot_contents, emit more smoke
    else
        if kind == "Soup" then -- or kind == "etc"; this only runs if we're cooking
            if baking <= 0 then
                local firstingr
                for i = 1, #inv do
                    local ingr = inv[i]:get_short_description()
                    if ingr ~= "" then
                        firstingr = ingr
                        break
                    end
                end
                if firstingr then
                    firstingr = firstingr:gsub(" %(uncooked%)","")
                    firstingr = firstingr:gsub("Unbaked ","")
                    firstingr = firstingr:gsub(" Carcass","")
                    firstingr = firstingr.." "
                end
                for i = 1, #inv do
                    inv[i]:clear()
                end
                spawn_steam(pos,{amt={22,45}})
                minetest.sound_play("tech_frying_final",{
                                        pos = pos,
                                        gain = 2,
                                        fade = 0.1,
                                        max_hear_distance = 13,
                })
                inv[1]:replace(ItemStack("tech:soup "..portions))
                local imeta = inv[1]:get_meta()
                local portion = divide_portions(total)
                portion.th = portion.th + (100 / portions)
                imeta:set_string("eat_value", minetest.serialize(portion))
                imeta:set_string("description", S("@1 soup",firstingr or "Odd"))
                meta:get_inventory(pos):set_list("main", inv)
                meta:set_string("contents_string",S("Contents: @1 soup",firstingr))
                meta:set_string("status_string",S("Status: @1 pot (finished)", S(kind)))
                meta:set_string("status", "finished")
                minimal.infotext_set_new(pos, meta) -- update infotext
                return
            elseif temp < cook_temp[kind] then
                if status ~= 'cooling' then
                    meta:set_string("status", "cooling")
                    meta:set_string("status_string",S('Status: @1 pot', S(kind)))
                    minimal.infotext_set_new(pos, meta)
                end
                return
            elseif temp >= cook_temp[kind] then
                if meta:get_inventory():is_empty("main") then
                    return
                end
                if status ~= 'cooking' then
                    meta:set_string('status', 'cooking')
                    meta:set_string('status_string',S("Status: @1 pot (cooking)", S(kind)))
                    minimal.infotext_set_new(pos, meta)
                    spawn_steam(pos,{amt={14,24}})
                    minetest.sound_play("tech_frying_start",{
                                            pos = pos,
                                            gain = 1,
                                            fade = 1,
                                            max_hear_distance = 12,
                    })
                else
                    spawn_steam(pos)
                    minimal.sound_play("tech_frying",{
                                           pos = pos,
                                           gain = {2,6},
                                           fade = 0.4,
                                           max_hear_distance = 10,
                    })
                end
                meta:set_int("baking", baking - 1)
            end
        end -- Soup
    end -- status == finished
end

local function calc_baking_time(stack)
    -- #TODO: Check if we're adding to a stack, don't alter
    local fname = stack:get_name()
    -- in order of priority;
    -- baking time
    -- already cooked
    -- use half of nutrition unit value
    local bake_data = HEALTH.bake_table[fname]
    local time = bake_data and bake_data.duration or fname:match("_cooked") and 1 or nil
    if not time then
        local ft = HEALTH.get_food_stats(fname)
        if not ft then return 0 end -- has no time to give
        return 1 + math.floor(math.abs(ft.hu)/2)
    end
    return time
end

-- On dig, ask if the player wants to dump the pot, losing the contents
local function spill_pot(returnedyes, data, player, playername)
    if returnedyes then
        local pot = minetest.get_node(data.spillpos)
        local potmeta = minetest.get_meta(data.spillpos)
        potmeta:set_string("type", "")
        minetest.node_dig(data.spillpos, pot, player)
    end
end

minetest.register_node(
    "tech:cooking_pot", {
        description = S("Cooking Pot"),
        tiles = {"tech_pottery.png",
                 "tech_pottery.png",
                 "tech_pottery.png",
                 "tech_pottery.png",
                 "tech_pottery.png"},
        drawtype = "nodebox",
        stack_max = minimal.stack_max_bulky,
        paramtype = "light",
        paramtype2 = "facedir",
        node_box = {
            type = "fixed",
            fixed = pot_box,
        },
        groups = {dig_immediate = 3, pottery = 1, heatable = 75 },
        sounds = nodes_nature.node_sound_stone_defaults(),
        on_construct = function(pos)
            clear_pot(pos)
        end,
        on_rightclick = function(...)
            return pot_rightclick(...)
        end,
        on_dig = function(pos, node, digger)
            local playername = digger:get_player_name()
            if minetest.is_protected(pos, playername) then
                return false
            end
            local meta = minetest.get_meta(pos)
            local inv = meta:get_inventory()
            local pottype = meta:get_string("type")
            if ( not inv:is_empty("main")
                 or pottype ~= "") then -- type is empty on uprepared pot
                minimal.yes_or_no(playername,
                                  S("This pot is full and heavy. "..
                                    "Spill it?"), spill_pot,
                                  { spillpos = pos } )
                return false
            end
            minetest.node_dig(pos, node, digger)
        end,
        on_receive_fields = function(...)
            pot_receive_fields(...)
        end,
        on_timer = function(pos, elapsed)
            pot_cook(pos, elapsed)
            return true
        end,
        allow_metadata_inventory_put = function(
                pos, listname, index, stack, player)
            local fname = stack:get_name()
            if not HEALTH.food_table[fname] and not HEALTH.bake_table[fname] then
                return 0
            end
            local meta = minetest.get_meta(pos)
            if meta:get_string("status") == "finished" then
                --prevent adding items after cooking is complete
                return 0
            end
            local inv = meta:get_inventory():get_list(listname)
            local count = stack:get_count()
            --if we put new items in during cook, extend "baking" time further
            meta:set_int("baking", meta:get_int("baking")
                         + calc_baking_time(stack))
            for i = 1, #inv do
                -- Only allow one stack of a given item
                if not (i == index) and inv[i]:get_name() == stack:get_name() then
                    return 0
                end
            end
            return count
        end,
        allow_metadata_inventory_take = function(
                pos, listname, index, stack, player)
            local meta = minetest.get_meta(pos)
            local status = meta:get_string("status")
            --prevent removing items once cooking begins
            if status ~= "" and status ~= "finished" then -- "" means cooking never started.
                return 0
            end
            meta:set_int("baking", meta:get_int("baking")
                         - calc_baking_time(stack))
            return stack:get_count()
        end,
        on_infotext = function(pos, nodedef, meta, params)
            params = minimal.infotext_update_params(meta, params)
            params.description = nodedef.description
            -- get proper owner string
            params = minimal.infotext_get_base_params(nil, meta, params)
            -- get base status'
            params.status_string = params.status_string or S("Unprepared Pot")
            params.contents_string = params.contents_string or S("Contents: <EMPTY>")
            params.note = params.note or S("Note: Add water to pot to make soup")
            if params.note == "nil" then params.note = nil end -- no note to add
            -- prioritize in order:
            -- status_string, owner, contents, note
            return params.status_string..(params.owner and params.owner ~= "" and "\n"..params.owner or "")..
                "\n"..params.contents_string..(params.note and "\n"..params.note or "")
        end,
        -- liquid_store_pourin callback
        -- so we don't need to set up functionality for water in pot_rightclick
        ls_pourin = function(itemstack, user, pos, source, selfdef)
            -- not even water we can use! return!
            if source ~= "nodes_nature:freshwater_source" then return end
            local meta = minetest.get_meta(pos)
            if meta:get_string("status") ~= "" then return end -- pot is active, return
            -- it's soupin' time
            meta:set_string("type","Soup")
            meta:set_string("status_string",S("Soup Pot"))
            meta:set_string("contents_string",S("Contents: Water"))
            meta:set_string("note",S("Note: Add food to the pot to make soup"))
            minimal.infotext_set_new(pos, meta)
            meta:set_string("formspec", pot_formspec)
            meta:set_int("baking", cook_time)
            -- revv up those cookin' engines!
            local timer = minetest.get_node_timer(pos)
            timer:start(6)
            if not minimal.player_in_creative(user) then
                return liquid_store.drain_store(user, itemstack)
            end
            return itemstack
            -- TODO: use oil for fried food, saltwater for salted food (to preserve it)
            -- XXX Was going to add ability to take water out of a prepared pot but more complicated
            -- then expected will try again later
            -- TPH: just see about using ls_fillup! :D ^^^
        end
})

minetest.register_node(
    "tech:cooking_pot_unfired", {
        description = S("Cooking Pot (unfired)"),
        tiles = {"nodes_nature_clay.png",
                 "nodes_nature_clay.png",
                 "nodes_nature_clay.png",
                 "nodes_nature_clay.png",
                 "nodes_nature_clay.png",
                 "nodes_nature_clay.png"},
        drawtype = "nodebox",
        stack_max = minimal.stack_max_bulky,
        paramtype = "light",
        paramtype2 = "facedir",
        node_box = {
            type = "fixed",
            fixed = pot_box,
        },
        groups = {dig_immediate=3, temp_pass = 1,
                  falling_node = 1, heatable = 20},
        sounds = nodes_nature.node_sound_stone_defaults(),
        on_construct = function(pos)
            ncrafting.set_firing(pos, ncrafting.base_firing,
                                 ncrafting.firing_int)
        end,
        on_dig = function(pos, node, digger)
            return ncrafting.on_dig_pottery(pos, node, digger,
                                            ncrafting.base_firing)
        end,
        on_timer = function(pos, elapsed)
            --finished product, length
            return ncrafting.fire_pottery(pos, "tech:cooking_pot_unfired",
                                          "tech:cooking_pot",
                                          ncrafting.base_firing)
        end,

})

crafting.register_recipe({
        type = {"crafting_spot","hand_pottery"},
        output = "tech:cooking_pot_unfired 1",
        items = {"nodes_nature:clay_wet 3"},
        level = 1,
        always_known = true,
})
crafting.register_recipe({
        type = {"mixing_spot","hand_pottery"},
        output = "nodes_nature:clay 3",
        items = {"tech:clay_water_pot_unfired 1"},
        level = 1,
        always_known = true,
})
