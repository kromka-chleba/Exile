backpacks = {}
storage = storage
-- Internationalization
local S = minetest.get_translator("backpacks")

local more_info = minetest.settings:get_bool('exile_backpacks_spreadsheet')

local colours = {
    full = "#90c8fc", -- pastel blue
    partial = "#90fca0", -- pastel green
    neutral = "#ffffff", -- white
    item_name = "#ffff7a" -- pastel yellow
}

local function get_formspec(pos, w, h)
    local meta = minetest.get_meta(pos)
    local creator = meta:get_string('creator')
    local label = minimal.sanitize_string(meta:get_string('label'))

    local formspec_size_h = 3.85 + h
    local main_offset = 1.85 + h
    local label_offset = 0.85 + h
    local creator_offset_x =  (3*(30-string.len(creator))/30/2) + 5
    local craftedby_offset_x = 6.05 -- 3*(30-string.len('crafted by'))/30/2 + 5

    local formspec = {
        "size[8,"..formspec_size_h.."]",
        "list[current_name;main;0,0.3;"..w..","..h.."]",
        "field[0.5,"..label_offset..";5,1;label;Label:;"..label.."]",
        "field_close_on_enter[label;false]",
        "button[5,"..label_offset..";1,0.25;labelset;Set]",
        "label["..craftedby_offset_x..","..(label_offset-.35)..";Crafted by:]",
        "label["..creator_offset_x..","..label_offset..";"..creator.."]",
        "list[current_player;main;0,"..main_offset..";8,2]",
        "listring[current_name;main]",
        "listring[current_player;main]",
    }
    minimal.infotext_set_new(pos, meta)
    return table.concat(formspec, "")
end

local function get_description(meta,bag_name,add_string)
    local desc = bag_name
    local label = meta:get_string('label')
    if label ~= '' then
        desc = desc.." - "..label
    end
    if type(add_string) == "string" and add_string ~= "" then
        desc = desc..add_string
    end
    return desc
end

-- set bag stats
-- return usable description
local function bagitem_set_stats_get_desc(item, imeta, item_inv, idef)
    imeta = imeta or item:get_meta()
    item_inv = item_inv or minimal.get_item_inventory(item, imeta)
    idef = idef or item:get_definition()
    local bag_name = idef.description
    local counts = item_inv:get_full_partial_empty_count()
    counts.size = item_inv:get_size()
    -- actually empty
    if counts.size == counts.empty then
        -- empty; no items, return empty_name
        imeta:set_string("inv_main","")
        return {desc = idef._empty_name}
    elseif counts.size == (counts.full + counts.partial) then
        bag_name = idef._full_name
    end
    -- set up text colours that'll be used
    local text_colours = {
        minetest.get_color_escape_sequence(colours["full"]), -- full
        minetest.get_color_escape_sequence(colours["partial"]), -- partial
        minetest.get_color_escape_sequence(colours["neutral"]), -- empty
        minetest.get_color_escape_sequence(colours["item_name"]) -- item_name
    }
    -- get translated or regular stats
    local slots = {
        text_colours[1]..(more_info and S("@1 full", counts.full) or counts.full),
        text_colours[2]..(more_info and S("@1 partial", counts.partial) or counts.partial),
        text_colours[3]..(more_info and S("@1 empty", counts.empty) or counts.empty)
    }
    -- create additional string to itemstack description
    local add_string
    -- more descriptive information wanted
    if more_info then
          local most_popular = item_inv:get_most_popular_stats()
          -- turn to number indexed table
          most_popular = {
              -- convert name to ItemStack
              ItemStack(most_popular.name),
              most_popular.count,
              most_popular.max
          }
          -- get description, add colour
          most_popular[1] = text_colours[4]..(most_popular[1]:get_short_description()
              or most_popular[1]:get_description())
          -- add slots
          slots = text_colours[3]..S("Slots: @1, @2, @3", slots[1], slots[2], slots[3])
          add_string = S("@n@1 @2/@3 @n@4", most_popular[1], most_popular[2], most_popular[3], slots)
    -- basic information
    else
        add_string = " "..S("- @1/@2/@3", slots[1], slots[2], slots[3])
    end
    -- set inventory
    imeta:set_string('inv_main', item_inv:convert())
    return {desc = bag_name, add = add_string}
end

local packdump_forms = {}
local function show_packdump_formspec(pos, playername, itemstack,
                                      can_dump, can_pack)
    if not (can_dump or can_pack) then return end
    playername = type(playername) == "string" and playername
        or type(playername) == "userdata"
        and type(playername.get_player_name) == "function"
        and playername:get_player_name()
        or nil
    if not playername then return end

    if type(itemstack) ~= "userdata" then return end -- not an itemstack
    local h = 2
    local buttons = {
        dump = can_dump and "button_exit[1.5,dumpheight;4,1;Dump;"..
            S("Dump Into Storage").."]",
        pack = can_pack and "button_exit[1.5,packheight;4,1;Pack;"..
            S("Pack Up Storage").."]"
    }
    local spec = ("formspec_version[3]"..
                  "size[7,specheight]"..
                  "hypertext[0.5,0.75;7,3;introtext;"..
                  itemstack:get_description().."]"..
                  "button_exit[6,0;1,1;Exit;X]")
    for bname,button in pairs(buttons) do
        if button then
            spec = spec..(button:gsub(bname.."height",h))
            h = h + 1.5
        end
    end
    spec = spec:gsub("specheight",h)
    minetest.show_formspec(
        playername, "backpacks:packdump",
        spec
    )
    packdump_forms[playername] = pos
end
minetest.register_on_player_receive_fields(function(player,
                                                    formname,fields)
        if formname ~= "backpacks:packdump" then return end
        if not (fields.Dump or fields.Pack) then return end
        -- don't go through the effort if they didn't press anything

        local pname = player:get_player_name()
        local pos = packdump_forms[pname]
        if not pos then return end
        -- function to remove info
        local function clear()
            packdump_forms[pname] = nil
            return
        end
        local itemstack = player:get_wielded_item()
        -- this will be important for later
        if itemstack:is_empty() then return clear() end
        -- or not, we don't even exist!

        -- get node meta + inventory
        local meta = minetest.get_meta(pos)
        local inv = meta:get_inventory()
        if not inv then return clear() end
        -- get node inventory
        local node_inv = minimal.convert_node_inventory(inv,"main")
        if not node_inv then return clear()  end
        -- item metadata (only access if we can get node inventory)
        local item_meta = itemstack:get_meta()
        -- get item inventory object, create an empty inventory if none found
        if not item_meta:get("inv_main") then -- create inventory to use
            item_meta:set_string("inv_main","return {}")
        end
        local item_inv = minimal.get_item_inventory(itemstack,
                                                    item_meta, "inv_main")
        if not item_inv then return clear() end
        -- get inventory lists
        local node_list = node_inv:get_list()
        local item_list = item_inv:get_list()
        -- simply updates inventory
        local function update_inv()
            inv:set_list("main",node_list)
            local info = bagitem_set_stats_get_desc(itemstack, item_meta, item_inv)
            -- Set Description
            item_meta:set_string('description', get_description(meta,
                                                            info.desc, info.add))
            --minimal.set_item_inventory(itemstack, item_meta,
            --                           "inv_main", item_inv)
            player:set_wielded_item(itemstack)
        end
        -- dump it all into that storage!
        if fields.Dump and (#node_inv:get_full() < node_inv:get_size()
                            and #item_inv:get_empty() ~= #item_list) then
            local def = minimal.get_nodedef(pos)
            for index,item in pairs(item_list) do
                local count = item:get_count()
                count = def.storage_inventory_dump_into and
                def.storage_inventory_dump_into(item, count, item_inv, index, node_inv) or count
                -- only modify inventory if count is greater than 0
                if count > 0 then
                    item = node_inv:add_item(item, nil, count)
                    item_list[index] = item
                end
            end
            update_inv()
            -- pack up that storage
        elseif fields.Pack and (#item_inv:get_full() < item_inv:get_size()) then
            local def = itemstack:get_definition()
            for index,item in pairs(node_list) do
                local count = item:get_count()
                count = def.storage_inventory_dump_into and
                    def.storage_inventory_dump_into(item, count, node_inv, index, item_inv) or count
                -- ditto to above
                if count > 0 then
                    item = item_inv:add_item(item, nil, count)
                    node_list[index] = item
                end
            end
            update_inv()
        end
        clear()
end)

local after_place_node = function(pos, placer, itemstack, pointed_thing)
    local node = minetest.get_node(pos)
    local meta = minetest.get_meta(pos)
    local imeta = itemstack:get_meta()

    -- Load inventory
    local inv_main = imeta:get_string('inv_main')
    local inv=meta:get_inventory()
    -- compatability for worlds created earlier then v0.3.9
    -- minetest.get_metadata() deprecated but old maps used it
    -- causes contents of backpacks stored in inventory to be forgotton
    local stuff = minetest.deserialize(itemstack:get_metadata())
    if stuff then
        local deprecated_inventory = stuff.inventory.main
        -- inv_main will be empty if stuff exists so safe to overwrite
        inv_main = minetest.serialize(deprecated_inventory)
    end
    if inv_main then
        inv:set_list('main',minetest.deserialize(inv_main))
    end
    -- set color
    if minetest.is_player(placer) == true then
        local face = { x = 0, y = 0, z = 1}
        local axis = { x = 0, y = 1, z = 0}
        local ldir = placer:get_look_horizontal()
        ldir = vector.rotate_around_axis(face, axis, ldir)
        local ndir = minetest.dir_to_wallmounted(ldir)
        local color = minetest.strip_param2_color(node.param2,
                                                  "colorwallmounted")
        node.param2 = color + ndir
        minetest.swap_node(pos, node)
    end
    if not minimal.player_in_creative(placer) then
        itemstack:take_item()
    end
end

local preserve_metadata = function(pos, oldnode, oldmeta, drops,width,height)
    local item = drops[1]
    local imeta = item:get_meta()
    local idef = item:get_definition()
    local bag_name = idef.description
    -- Transfer inventory to item
    local meta = minetest.get_meta(pos)
    local inv = minimal.convert_node_inventory(meta)
    local info = bagitem_set_stats_get_desc(item, imeta, inv, idef)
    -- Set color
    local color = minetest.strip_param2_color(oldnode.param2,
                                              "colorwallmounted")
    imeta:set_int('palette_index', color)
    -- Set Description
    imeta:set_string('description', get_description(meta,
                                                    info.desc, info.add))
    -- Set Formspec
    imeta:set_string('formspec', get_formspec(pos,width,height))
end

local on_dig = function(pos, node, digger, width, height)
    if minetest.is_protected(pos, digger:get_player_name()) then
        return false
    end
    local player_inv = digger:get_inventory()
    -- See if it fits in invenotry
    local new = ItemStack(node)
    if player_inv:room_for_item("main", new) then
        --Call default node_dig() to remove node and make item
        --Causes preserve_metadata() to be called.
        return minetest.node_dig(pos, node, digger)
    end
    return false
end

local wallmount_box = {
    type = "fixed",
    fixed = {
        {-0.4375, -0.375, -0.5, 0.4375, 0.375, 0.5}, -- NodeBox1
        {0.125, -0.5, -0.375, 0.375, -0.4375, 0.3125}, -- NodeBox2
        {-0.375, -0.5, -0.375, -0.125, -0.4375, 0.3125}, -- NodeBox3
        {0.125, -0.4375, 0.1875, 0.375, -0.375, 0.375}, -- NodeBox4
        {-0.375, -0.4375, 0.1875, -0.125, -0.375, 0.375}, -- NodeBox5
        {0.125, -0.4375, -0.375, 0.375, -0.375, -0.25}, -- NodeBox6
        {-0.375, -0.4375, -0.375, -0.125, -0.375, -0.25}, -- NodeBox7
        {-0.3125, 0.375, -0.375, 0.3125, 0.4375, 0.1875}, -- NodeBox8
        {-0.25, 0.4375, -0.315, 0.25, 0.5, 0.125}, -- NodeBox9
    }
}


-- backpacks
function backpacks.register_backpack(name, def)
    -- cause errors if incorrect values given
    assert(type(name) == "string",
           "backpacks.register_backpack: given 'name' is not a string! Got '"
           ..type(name).."'")
    assert(type(def) == "table",
           "backpacks.register_backpack: Incorrect value given for expected "..
           "definition table, got '"..type(def).."'")
    assert(type(def.sounds) == "table",
           "backpacks.register_backpack: did not get a proper sounds table, "..
           "got '"..type(def.sounds).."'")
    -- correct values
    def.description = def.description or ""
    def.groups = def.groups or {}
    def.groups.backpack = 1
    -- if dig_immediate is 0 or less then remove from groups
    def.groups.dig_immediate =
        def.groups.dig_immediate and (def.groups.dig_immediate > 0
                                      and def.groups.dig_immediate or nil)
        or 3
    -- permit texture/textures, def.tiles string
    def.texture = def.texture or
        def.textures
        or type(def.tiles) == "string" and def.tiles
    -- permit a tiles override
    if type(def.tiles) ~= "table" then -- create one
        def.tiles = {
            -- rotated onto its back for correct wallmounted dirs
            "backpacks_backpack_front.png", -- Front
            "backpacks_backpack_back.png",      -- Back
            "backpacks_backpack_sides-rotated.png",-- Right Side
            "backpacks_backpack_sides-rotated.png",-- Left Side
            "backpacks_backpack_topbottom.png", -- Top
            "backpacks_backpack_topbottom.png", -- Bottom
        }
        local texture = def.texture
        if type(texture) == "string" then
            -- add texture to backpack
            for tile_index,tile in pairs(def.tiles) do
                def.tiles[tile_index] = texture.."^"..tile
            end
        end
    end
    -- custom "empty_name" and "full_name"
    def._empty_name = def._empty_name or def.empty_name or def.description
    def._full_name = def._full_name or def.full_name or def.description
    -- can_dump and can_pack
    def.can_dump = type(def.can_dump) ~= "boolean" and true or def.can_dump
    def.can_pack = type(def.can_pack) ~= "boolean" and true or def.can_pack
    -- use tip related (use_tips do not properly display)
    --def._use_tip = (def.can_dump and def.can_pack and "Dump or pack"
    -- or def.can_dump and "Dump" or def.can_pack and "Pack") or nil
    --def._use_tip = def._use_tip and ("@1 contents into storage",S(def._use_tip))
    -- formspec params
    def.formspec_width = def.formspec_width or def.width
    def.formspec_height = def.formspec_height or def.height
    -- cleanup of def
    def.empty_name = nil
    def.full_name = nil
    def.width = nil
    def.height = nil
    -- basic def stuff
    def.paramtype2 = def.paramtype2 or "colorwallmounted"
    def.palette = "natural_dyes.png"
    def.drawtype = def.drawtype or "nodebox"
    def.node_box = def.node_box or def.drawtype == "nodebox" and wallmount_box
    def.stack_max = def.stack_max or 1
    def.node_placement_prediction = def.node_placement_prediction or ""
    def.can_dig_when_inventory =
        type(def.can_dig_when_inventory) ~= "boolean" and true
        or def.can_dig_when_inventory
    -- functions
    def.after_place_node = def.after_place_node
        or function(pos, placer, itemstack, pointed_thing)
            after_place_node(pos, placer, itemstack, pointed_thing)
            storage.on_construct(pos, def.formspec_width, def.formspec_height)
        end
    def.on_dig = def.on_dig or
        function(pos, node, digger)
            on_dig(pos, node, digger, def.formspec_width, def.formspec_height)
        end
    def.preserve_metadata = def.preserve_metadata
        or function(pos, oldnode, oldmeta, drops)
            preserve_metadata(pos, oldnode, oldmeta, drops,
                              def.formspec_width, def.formspec_height)
        end
    def._on_use_item = function(player, itemstack, pointed_thing)
        if not (pointed_thing and pointed_thing.under) then return end
        local pos = pointed_thing.under
        local ndef = minimal.get_nodedef(pos)
        if not (ndef and ndef.groups) then return end
        -- needs to be storage or bones
        if not (ndef.groups.storage or ndef.name == "bones:bones") then return end
        if ndef.groups.no_packdump then return end
        local pname = player:get_player_name()
        if minetest.is_protected(pos,pname) then return end
        show_packdump_formspec(pos, player, itemstack,
                               (def.can_dump
                                and not ndef.groups.no_dump),
                               (def.can_pack
                                and not ndef.groups.no_pack))
    end
    -- infotext handling
    def.on_infotext = def.on_infotext or function(pos, nodedef, meta, params)
        params.description = def.description
        params = minimal.infotext_update_params(meta, params)
        return minimal.infotext_get_base_string(nil, meta, params)
    end
    -- register backpack through storage.register_storage()
    storage.register_storage(":backpacks:backpack_"..name,def)
end
