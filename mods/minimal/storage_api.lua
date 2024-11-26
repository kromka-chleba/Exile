storage = {}

local modname = "minimal/storage_api.lua"

local S = minimal.S

-- functionality for determining if a player is looking in storage
local get_watchers = minimal.get_watchers
local add_watcher = minimal.add_watcher
local remove_watcher = minimal.remove_watcher

function storage.get_storage_formspec(pos, w, h, meta)
    local creator = meta:get_string('creator')
    local label = minimal.sanitize_string(meta:get_string('label'))
    meta:set_string("label",label)
    minimal.infotext_set_new(pos, meta)
    local formspec_size_h = 3.85 + h
    local main_offset = 0.25 + h
    local trash_offset = 0.45 + h + 2
    local label_offset = trash_offset + .35
    local creator_offset_x =  (3*(30-string.len(creator))/30/2) + 5
    local craftedby_offset_x = 6.05 -- 3*(30-string.len('crafted by'))/30/2 + 5

    local formspec = {
        "size[8,"..formspec_size_h.."]",
        "list[current_name;main;0,0;"..w..","..h.."]",
        "list[current_player;main;0,"..main_offset..";8,2]",
        "listring[current_name;main]",
        "listring[current_player;main]",
        "list[detached:creative_trash;main;0,"..trash_offset..";1,1;]",
        "image[0.05,"..(trash_offset+.10)..
            ";0.8,0.8;creative_trash_icon.png]",
        "field[1.5,"..label_offset..";4,1;label;"..
            S("Label")..":;"..label.."]",
        "field_close_on_enter[label;false]",
        "button[5,"..label_offset..";1,0.25;labelset;"..S("Set").."]",
        --"label["..craftedby_offset_x..","..trash_offset..";Crafted by:]",
        --"label["..creator_offset_x..","..(trash_offset+.35)..";"..creator.."]",
    }
    if (creator and creator ~= '') then
        formspec[#formspec + 1] = "label["..craftedby_offset_x..","..trash_offset..
            ";"..S("Crafted by")..":]"
        formspec[#formspec + 1] = "label["..creator_offset_x..
            ","..(trash_offset+.35)..";"..creator.."]"
    end
    return table.concat(formspec, "")
end


local function can_interact(pos, name, meta)
    if minetest.is_protected(pos, name, meta) then
        -- you are NOT the owner!
        return false
    end
    -- returns true if the node isn't protected from the player lol
    return true
end

function storage.can_dig(pos,player,can_grab)
    local inv_empty = true
    local meta = minetest.get_meta(pos)

    if not can_grab then
        local inv = meta:get_inventory()
        inv_empty = inv:is_empty("main")
    end

    return can_interact(pos, player, meta) and inv_empty
end

function storage.on_construct(pos, width, height)
    local meta = minetest.get_meta(pos)

    local form = storage.get_storage_formspec(pos, width, height, meta)
    meta:set_string("formspec", form)

    local inv = meta:get_inventory()
    inv:set_size("main", width*height)
end

function storage.on_receive_fields(pos, formname, fields, sender, width, height)
    local label = fields.label
    -- only get meta if label was modified and sender is a player
    local meta = label and minetest.is_player(sender) and minetest.get_meta(pos)
        or nil
    -- thus we can use meta to check if we can set up the new label
    if meta and can_interact(pos,sender, meta) then
        local cleanlabel = minimal.sanitize_string(label)
        meta:set_string('label', cleanlabel)
        minimal.infotext_set_new(pos, meta)
        storage.on_construct(pos, width, height)
        -- we're just closing storage
        -- sounds
    else
        remove_watcher(pos, sender)
        -- only play sounds if no more folk are watching
        --   and if not protected from watcher
        if #get_watchers(pos) < 1
            and not minetest.is_protected(pos, sender, meta) then

            minimal.sound_play_watcher(pos, nil, false)
        end
    end
end

-- basic dump_inventory function
-- optional meta argument
function storage.dump_inventory(pos, meta)
    assert(type(pos) == "table","mods/"..modname..
           "dump_inventory: Invalid pos provided!")
    assert( (type(pos.x) == "number" and type(pos.y) == "number"
             and type(pos.z) == "number"),
        "mods/"..modname.."dump_inventory: Invalid pos provided!")

    -- verify if the dumped inventory belongs to a storage container
    local stor_node = minetest.get_node(pos)
    if not minimal.is_group(stor_node.name,"storage") then return end

    meta = type(meta) == "userdata" and meta or minetest.get_meta(pos)
    -- don't attempt to empty out an empty inventory
    local inv = meta:get_inventory()
    if inv:is_empty("main") then
        return
    end

    -- empty it out!
    local dump_pos = {x = pos.x, y = pos.y + 1, z = pos.z}
    for _,itemstack in pairs(inv:get_list("main")) do
        itemstack = inv:remove_item("main",itemstack)

        -- drop items
        minetest.item_drop(itemstack, nil, dump_pos)
    end
end

-- to_burnt
-- optional meta argument, otherwise gets meta
local function to_burnt(pos, meta)
    local stor_node = minetest.get_node(pos)
    if not minimal.is_group(stor_node.name,"storage") then
        return -- not storage, why did this get ran?
    end
    stor_node = minetest.registered_nodes[stor_node.name]
    local burn_to = stor_node.burn_to
    -- can't be burned lol
    if type(burn_to) ~= "string" then
        return
    end
    -- if burn_to empty, assume air, otherwise use burn_to
    burn_to = burn_to == "" and "air" or burn_to
    burn_to = minetest.registered_nodes[burn_to]
    -- could not find burn_to node
    if not burn_to then return end

    meta = type(meta) == "userdata" and meta or minetest.get_meta(pos)
    if type(stor_node.metadata_inventory_dump) == "function" then
        -- run on_dump code
        stor_node.metadata_inventory_dump(pos, meta)
    end

    -- if burn_to node is not storage then don't try to add storage aspects to it!
    if not minimal.is_group(stor_node.burn_to,"storage") then return end

    -- creating burn_to storage variant
    -- get formspec width and height
    local width = stor_node.formspec_width or 8
    local height = stor_node.formspec_height or 4

    -- set formspec_width and formspec_height as meta_int
    meta:set_int("formspec_width",width)
    meta:set_int("formspec_height",height)

    -- does the inventory saving for me :D \/ (as well as saves owner, label, and the width and height metadata)
    minimal.switch_node(pos,{name = burn_to.name})
end

function storage.register_storage(name,def)
    assert(type(name) == "string","mods/"..modname..
           ".register_storage: No string provided for name!")
    assert(type(def) == "table","mods/"..modname..
           ".register_storage: No table provided for definition!")

    def.groups = def.groups or {}
    def.groups.storage = 1
    def.stack_max = def.stack_max or minimal.stack_max_bulky
    def.drawtype = def.drawtype or "nodebox"
    def.node_box = def.node_box
        or def.drawtype == "nodebox" and
        {
            -- basic storage container shape
            type = "fixed",
            fixed = {
                {-0.375, -0.5, -0.375, 0.375, -0.375, 0.375},
                {-0.375, 0.375, -0.375, 0.375, 0.5, 0.375},
                {-0.4375, -0.375, -0.4375, 0.4375, -0.25, 0.4375},
                {-0.4375, 0.25, -0.4375, 0.4375, 0.375, 0.4375},
                {-0.5, -0.25, -0.5, 0.5, 0.25, 0.5},
            }
        }
    def.paramtype = "light"
    -- custom values
    -- formspec for storage inventory
    def.formspec_width = def.formspec_width or 8
    def.formspec_height = def.formspec_height or 4
    -- integers only
    def.formspec_width = math.ceil(def.formspec_width)
    def.formspec_height = math.ceil(def.formspec_height)
    -- automatic protection
    def.protected = def.protected == true and true or false
    -- can be dug if there's itemstacks inside (default false)
    def.can_dig_when_inventory =
        def.can_dig_when_inventory == true and true or false
    -- legacy usage for flammable setting
    def.groups.flammable = def.groups.flammable or def.burnable and 1
    def.burnable = nil
    -- what to burn to when set ablaze, sets a default if flammable
    def.burn_to = def.burn_to
        or def.groups.flammable and "minimal:burnt_storage_pile"
        or nil
    -- functions
    def.allow_metadata_inventory_move = def.allow_metadata_inventory_move or
        function(pos, from_list, from_index, to_list, to_index, count, player)
            if can_interact(pos, player) then
                return count
            end
            return 0
        end

    def.allow_metadata_inventory_put = def.allow_metadata_inventory_put or
        function(pos, listname, index, stack, player)
            if not can_interact(pos, player) then return 0 end
            local count = stack:get_count()
            local nodedef = minimal.get_nodedef(pos)
            count = nodedef.storage_inventory_dump_into and nodedef.storage_inventory_dump_into(stack, count) or count
            return count
        end

    def.allow_metadata_inventory_take = def.allow_metadata_inventory_take or
        function(pos, listname, index, stack, player)
            if can_interact(pos, player) then
                return stack:get_count()
            end
            return 0
        end
        
    -- custom storage function for filtering
    -- check minimal/utility/item.lua for what to expect with inv and target_inv
    -- inv is our inventory, index is where in the inventory the itemstack is
    -- target_inv is the inventory we're targeting
    -- DO NOT EXPECT INV, INDEX, OR TARGET_INV - CHECK FOR THEM!
    def.storage_inventory_dump_into = def.storage_inventory_dump_into or
        function(stack, count, inv, index, target_inv)
            count = count or stack:get_count()
            local stackdef = stack:get_definition()
            if not stackdef then return count end
            if stackdef.groups.backpack then
                local imeta = stack:get_meta()
                local item_inv = minimal.get_item_inventory(stack, imeta)
                if item_inv then
                    -- no inventory contents, we shall add stack added!
                    if #item_inv:get_empty() == item_inv:get_size() then
                        return count
                    end
                    return 0
                end
                -- no inventory, return!
                return count
            end
            -- stack is not a backpack continue as normal
            return count
        end

    def.on_blast = def.on_blast or function(pos) end
    --def.metadata_inventory_dump = def.metadata_inventory_dump or function(pos, meta)
    --storage.dump_inventory(pos, meta)
    --end
    -- declaring locals for formspec details (makes it easier to set up functions)
    local width = def.formspec_width
    local height = def.formspec_height
    -- basic functions
    def.can_dig = def.can_dig or function(pos, player)
        return storage.can_dig(pos, player, def.can_dig_when_inventory)
    end

    def.on_receive_fields = def.on_receive_fields or function(pos, formname,
                                                              fields, sender)
        storage.on_receive_fields(pos, formname, fields, sender, width, height)
    end

    def.on_construct = def.on_construct or function(pos)
        storage.on_construct(pos, width, height)
    end

    def.after_place_node = def.after_place_node or function(pos, placer,
                                                            itemstack,
                                                            pointed_thing)
        --Update formspec and infotext
        if (minetest.is_player(placer) and def.protected == true) then
            local p_name = placer:get_player_name() or ""
            minetest.get_meta(pos):set_string("owner", p_name)
        end
        storage.on_construct(pos, width, height)
    end

    def.on_rightclick = def.on_rightclick or function(pos, node, clicker,
                                                      itemstack, pointed_thing)
        if minetest.is_protected(pos, clicker) then
            return -- no touchy touchy
        end
        -- sounds
        if #get_watchers(pos) < 1 then
            minimal.sound_play_watcher(pos)
        end
        add_watcher(pos, clicker)
    end

    def.on_burn = def.on_burn or def.burn_to and function(pos)
        to_burnt(pos)
    end

    -- register the node
    minetest.register_node(name,def)
end

-- burnt storage pile code
local burnt_storage = {
    description = S("Burnt Storage Pile"),
    tiles = {"minimal_burnt_pile.png"},

    node_box = {
        type = "fixed",
        fixed = {
            {-0.45 , -0.5, -0.45,   0.45, -0.3, 0.45}, -- first layer
            {-0.35 , -0.3, -0.35,   0.35, -0.2, 0.35},
            {-0.2 , -0.2, -0.2,   0.2, -0.15, 0.2},
        },
    },

    groups = {burnt = 1, dig_immediate = 3, no_dump = 1},

    on_construct = function(pos)
        local meta = minetest.get_meta(pos)
        local width = meta:get_int("formspec_width")
        local height = meta:get_int("formspec_height")
        if (width ~= 0 and height ~= 0) then
            storage.on_construct(pos,width,height)
        else
            storage.on_construct(pos,8,4)
        end
    end,
    allow_metadata_inventory_put = function(pos, listname, index, stack, player)
        -- do not allow players to use the burnt storage
        return 0
    end,
    -- make after_place_node and on_receive_fields nil
    after_place_node = function()
    end,
    on_receive_fields = function()
    end,
}

storage.register_storage("minimal:burnt_storage_pile",burnt_storage)
