-- minimal/protection.lua
--
-- This may need to moved someplace else eventually.

local S=minimal.S
creative = creative
minimal = minimal

local __nail_use_count = 3

function minimal.protection_is_ownable(pos)
    if not pos then return end -- no pos
    local node = core.get_node(pos)
    if node.name == 'tech:stick' or core.get_item_group(node.name, 'flora') > 0 or
      core.get_item_group(node.name, 'unclaimable') > 0 then
        -- can't touch this
        return false
    end
    -- can claim this
    return true
end

local __open_access_list={}

function minimal.protection_key_click(itemstack, clicker, pos, meta)
    if not core.is_player(clicker) then return end -- not a player
    pos = minimal.get_usable_position(pos)
    meta = meta or minetest.get_meta(pos)
    local player_name = clicker:get_player_name()
    local owner = meta:get_string('owner')
    -- cannot modify for though we're not the rightful owner
    if owner ~= player_name then
        return
    end

    local fs_list ="";
    local list_json = meta:get_string("access_list")
    if list_json and list_json ~= '' then
        local access_list = minetest.parse_json(list_json)
        if access_list and #access_list > 0 then
            fs_list = table.concat(access_list, ",")
        end
    end

    if fs_list ~= '' then
        __open_access_list[player_name] = { pos = pos, meta = meta }
        local formspec = table.concat({"formspec_version[6]",
            "size[10.5,4]box[0.4,0.9;9.8,1.6;red]",
            "label[4.3,0.5;",S("Access List"),"]",
            "dropdown[1.1,1.35;4.8,0.7;access_list;"
            ,fs_list,";1;false]button_exit[6.6,1.3;3,0.8;Delete;",
            S("Delete"),"]button_exit[3.7,2.8;3,0.8;Close;",
            S("Close"),"]"})
        minetest.show_formspec(player_name, "protection:access_list", formspec)
    else
        minetest.chat_send_player(player_name, S("Access list empty."))
    end

end

local function remove_access_list_view(pname)
    __open_access_list[pname] = nil
    return true
end

minetest.register_on_player_receive_fields(
    function(player,formname,fields)
        if formname ~= "protection:access_list" then
            return
        end
        local pname = player:get_player_name()
        if not __open_access_list[pname] then return end -- no data, how did you open this?
        -- exited formspec regularly (not pressing on delete)
        if fields.quit and not fields.Delete then return remove_access_list_view(pname) end
        -- shuffling through who to remove then
        if not fields.Delete then return true end
        -- properly pressed on Delete, see what to do
        local meta = __open_access_list[pname].meta
        if not meta then return remove_access_list_view(pname) end -- how unfortunate, no meta!
        local list_json = meta:get_string("access_list")
        if list_json == '' then return remove_access_list_view(pname) end -- no information
        local access_list = core.parse_json(list_json)
        for i,granted in ipairs(access_list) do
            if granted == fields.access_list then
                table.remove(access_list, i)
                core.chat_send_player(pname,
                  S("Deleted @1 from access list.",
                    fields.access_list))
                break
            end
        end
        -- write out json
        if #access_list > 0 then
            meta:set_string("access_list",
              minetest.write_json(access_list))
        -- clear out json, no more in access list!
        else
            meta:set_string("access_list", '')
        end
        return remove_access_list_view(pname)
    end
)

function minimal.protection_key_use( itemstack, user, pos, meta )
    if not core.is_player(user) then return end
    pos = minimal.get_usable_position(pos)
    if not minimal.protection_is_ownable(pos) then return end -- shouldn't be able to do anything with this
    local pname = user:get_player_name()
    meta = meta or core.get_meta(pos)
    local owner = meta:get_string('owner')
    -- no owner here or we don't own this
    if owner == "" or pname ~= owner then
        minetest.chat_send_player(pname,
          S("Can't grant access to items you don't own"))
        return
    end
    local key = itemstack:get_meta():get_string("creator") -- creator of key (key owner)
    -- get list
    local list = meta:get_string("access_list")
    list = list ~= "" and core.parse_json(list) or {}
    -- let's see if we're already in here
    for _,name in ipairs(list) do
        -- ah! we're already here, return!
        if name == key then
            minetest.chat_send_player(pname,
              S("@1 already has access",
                key))
            return
        end
    end
    -- let's add the key owner to list
    table.insert(list, key)
    meta:set_string("access_list",
      minetest.write_json(list))
    minetest.chat_send_player(pname,
      S("@1 granted access",
      key))
end

function minimal.protection_nail_use( user, itemstack, pos, meta )
    if not core.is_player(user) then return end
    pos = minimal.get_usable_position(pos)
    if not minimal.protection_is_ownable(pos) then return end -- shouldn't be able to do anything with this
    meta = meta or core.get_meta(pos)
    if meta:get_string("owner") ~= "" then return end -- has an owner already, return!
    -- let's claim this meta for us!
    local owner = user:get_player_name()
    meta:set_string("owner", owner)
    meta:set_string("nailed", owner)
    -- take nails if player isn't in creative
    if not (minimal.player_in_creative(user)) then
        itemstack:take_item()
    end
    minimal.infotext_set_new(pos, meta)
    -- check for hammering sound and play it
    local idef = itemstack:get_definition()
    if idef.sounds and idef.sounds.nail_down then
        minimal.sound_play(minimal.merge_tables(idef.sounds.nail_down, {pos = pos}))
    end
    return itemstack
end


-- Set owner for protected items.
function minimal.protection_after_place_node( pos, placer, itemstack,
                                              pointed_thing )
    local pn = placer:get_player_name()
    local meta = minetest.get_meta(pos)
    meta:set_string("owner", pn)
    minimal.infotext_set_new(pos, meta)
    return minimal.player_in_creative(placer)
end

function minimal.protection_on_dig(pos,oldnode,digger,meta)
    if not core.is_player(digger) then return end -- not a player
    -- undefined node, or not allowed to dig (like a full backpack)
    local def = minetest.registered_nodes[oldnode.name]
    if not def or (def.can_dig and not def.can_dig(pos, digger) ) then
        return
    end
    -- Handles removal of nails from nodes protected by them
    meta = meta or minetest.get_meta(pos)
    local mdata = meta:to_table()
    local fields = mdata and mdata.fields
    if not fields then return end -- oops, all funkiness! (couldn't to_table() )
    if not fields.nailed then return end -- wasn't nailed
    if not fields.owner or fields.owner == "" then
        minetest.log("error", "Blank owner for nailed item "..def.name..
                     " at "..minetest.pos_to_string(pos))
    end
    if fields.owner ~= digger:get_player_name() then return end -- you are NOT the owner!
    --give digger back the nails (if they're not in creative)
    if not minimal.player_in_creative(digger) then
        local inv = digger:get_inventory()
        if inv:room_for_item("main", 'tech:nails') then
            inv:add_item("main",'tech:nails')
        else
            minimal.warn_inv_full(digger)
            minetest.add_item(pos, 'tech:nails')
        end
    end
    -- remove owner and nailed from meta properly
    fields.owner = nil
    fields.nailed = nil
    meta:from_table(mdata)
end
