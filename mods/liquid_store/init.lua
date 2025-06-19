

liquid_store = {}
liquid_store.containers = {}
liquid_store.liquids = {}
--[[ list of registered stored liquid, table has following format :
        liquid_store.stored_liquids[name] = {
            nodename : name of the node, ex "tech:clay_water_pot_freshwater"
            source : source, ex "nodes_nature:freshwater_source"
            nodename_empty : container, ex "tech:clay_water_pot"
            dumpable : is the liquid dumpable
        }
]]
liquid_store.stored_liquids = {}

-- registering containers and their groups to be used in crafting/unit
function liquid_store.register_container(name, groups)
    if not name then
        core.log("in liquid_store.register_container: "
            .. "missing name, registration cancelled")
        return
    end
    if not groups then
        groups = {}
    elseif type(groups) ~= "table" then
        core.log("in liquid_store.register_container: "
            .. "group given doesn't have correct format: "
            .. "Table expected, got: " .. type(groups))
        groups = {}
    end
    -- Add container groups to be inherited by filled versions
    -- and used in crafting recipes
    liquid_store.containers[name] = groups
end

--Liquids that it is possible to put in a bucket
-- register liquids in liquid_store.liquids
-- all group organization still to improve
function liquid_store.register_liquid(source, def)
    if not source then
        core.log ("missing source in liquid_store.register_liquid")
        return
    end
    -- try to get info frome node's definition if missing
    if not def then
        def = {}
    end

    -- will remain nil if not registered as node
    if def.flowing == nil then -- warning, could be 'false', don't replace by "if not ..."
        local i_def = core.registered_nodes[source]
        if i_def then
            def.flowing = i_def.liquid_alternative_flowing
        end
    end

    -- adds group of stored liquid in liquids groups for recipes
    local groups = def.groups or {}

    liquid_store.liquids[source] = {
        source = source,
        flowing = def.flowing,
        force_renew = def.force_renew, -- default is false
        description = def.description,
        groups = groups
    }
end

local on_scoop_change = {}
--Transform the named liquid into the replacement when picked up with a pot
-- stores what need to be changed in on_scoop_change table
-- NOTE: none is currently (2025-06-11) registered.
-- Do we need to keep it for compatibility reasons ?
function liquid_store.register_scoop_change(name, replacement)
    if ( not minetest.registered_nodes[name] ) or
        ( not minetest.registered_nodes[replacement] ) then
        minetest.log("error", "liquid_store: tried to register invalid scoop"..
                     "change: "..name.." vs "..replacement)
        return
    end
    on_scoop_change[name] = replacement
end

function liquid_store.contents(nodename)
    --To be called when you need to know if something's a valid liquid
    --Stores will return their source name; regular nodes will pass through
    local liquiddef = liquid_store.stored_liquids[nodename]
    if liquiddef ~= nil then
        return liquiddef.source
    else
        return nodename
    end
end

--[[get the empty container of a stored liquid
    *`nodename` as in  "tech:clay_water_pot_freshwater"
    * if `nodename` is not a valid stored liquid, returns nil
      else return the container as in "tech:clay_water_pot"
]]
function liquid_store.get_empty(nodename)
    local liquiddef = liquid_store.stored_liquids[nodename]
    if liquiddef ~= nil then
        return liquiddef.nodename_empty
    else
        core.log(nodename .. "is not a valid registered stored liquid")
        return nil
    end
end

--[[ allow `input` to be
    * a string,
    * or a table or userdata (usually itemstack) with a "name" index or "get_name" function
]]
local function check_input(input)
    if type(input) == "string" then
        return input
    elseif  type(input) == "table" or type(input) == "userdata" then
        input = input.name
                or type(input.get_name) == "function" and input:get_name()
                or nil
        if input == "" then
            input = nil -- don't look for a literally empty index
        end
    end
    return input
end

-- get a stored liquid's definition table
function liquid_store.get_sl_def(nodename,producefake)
    -- get stored liquid definition
    -- permit string, or any table or userdata with a name index or get_name function
    nodename = check_input(nodename)
    local sl_def
    if nodename then
        sl_def = liquid_store.stored_liquids[nodename]
    end
    -- return sl_def or if wanted, a fake stored_liquid definition
    if sl_def then
        return sl_def
    else
        if producefake == true then
            return {source="",nodename_empty="",dump=false}
        else
            return nil
        end
    end

end

local function check_protection(pos, user, text)
    local name = (minetest.is_player(user) and user:get_player_name()) or ""
    if minetest.is_protected(pos, name) then
        name = (name ~= "" and name or "A mod")
        minetest.log("action", name.. " tried to " .. text
                     .. " at protected position "
                     .. minetest.pos_to_string(pos)
                     .. " with a bucket")
        minetest.record_protection_violation(pos, name)
        return true
    end
    return false
end

-- handle punching + finding if it is a node
local function handle_interaction(player, pointed_thing)
    if not pointed_thing then
        return
    end
    if pointed_thing.type == "node" then
        return "node"
    elseif pointed_thing.type == "object" and pointed_thing.ref then
        pointed_thing.ref:punch(player, 1.0, { full_punch_interval=1.0 }, nil)
    end
    return pointed_thing.type
end

-- find_stored liquid name
--[[ helps find a stored liquid variant with the provided empty and source
    `empty` is the empty container (ex: "tech:clay_water_pot")
    `source` is the liquid (ex: nodes_nature:freshwater_source")
    return the name of the stored lquid (ex: "tech:clay_water_pot_freshwater")
    ]]
local function find_stored(empty, source)
    -- allow empty and source to be a string, or a table or userdata,
    -- (usually itemstack) with a "name" index or "get_name" function
    empty = check_input(empty)
    source = check_input(source)

    if not (empty and source) then return end -- return nothing

    for slname,sl in pairs(liquid_store.stored_liquids) do
        -- if empty and source found in relation to stored liquid name,
        --   then return the name
        if sl.nodename_empty == empty and sl.source == source then
            return slname
        end
    end
end
-- namespace
liquid_store.find_stored = find_stored

-- liquid_metadata
-- pos, oldnode, transferred_stack
-- store metadata into a provided stack (grab liquid)
local function liquid_metadata(pos, oldnode, t_stack)
    local nodedata = minetest.registered_nodes[oldnode.name]
    if type(t_stack) ~= "userdata" then
        core.log("in liquid_store liquid_metadata, t_stack needs to be an ItemStack to have metadat transferred to it")
        return
    end
    if type(nodedata) ~= "table"  then
        core.log("in liquid_store liquid_metadata, oldnode's def couldn't be found")
        return
    end

    -- custom metadata function I created for certain nodes
    if (type(nodedata._preserve_metadata) == "function") then
        local oldmeta = minetest.get_meta(pos)

        -- I removed the return, since called functions (fermentation) don't return anything, it was confusing...
        nodedata._preserve_metadata(pos, oldnode, oldmeta, t_stack)
    end
end

-- handles liquid transfer in case we had a stack in hand
-- NOTE: it was copy pasted from soup_handle_inventory in tech/cookig_pot.lua
-- #TODO it should probably be a more general function, in minimal maybe.
-- itemstack is what will be depleted/replaced
-- adding is what we're adding to the player's inventory
-- user is the player/entity performing this action
-- NOT REQUIRED PARAMETER: inv is the inventory of "user" - will be grabbed from "user" if not provided
local function handle_newstack(itemstack, adding, user, inv)
    -- get inventory if not provided (permits use by custom entities)
    inv = inv or (type(user) == "table" or type(user) == "userdata")
        and user.get_inventory and user:get_inventory()
    if not inv then return end
    -- inventory functionality
    local plr_creative = minimal.player_in_creative(user)
    local deplete_stack = false -- depleting instead of replacing
    --[[if we had a stack in hand, or player is in creative,
    original item will not be replaced,
    new one will be added elsewhere in inventory]]
    if itemstack:get_count() > 1 or plr_creative then
        if inv:room_for_item("main", adding) then
            deplete_stack = not plr_creative and true
            inv:add_item("main", adding)
        -- can't add, warn player
        elseif core.is_player(user) then
            deplete_stack = not plr_creative and true -- deplete anyways but one day fix this
            -- also drop at feet
            core.add_item(user:get_pos(), adding)
            minimal.warn_inv_full(user)
        end
    --else, lets just replace theone we had in hand
    else
        itemstack = adding
    end
    -- take away 1 itm of the stack if needed
    if deplete_stack then
        itemstack:take_item()
    end
    -- returns new itemstack to replace old one
    return itemstack
end

liquid_store.handle_newstack = handle_newstack


function liquid_store.drain_store(player, itemstack)
    local itemname = itemstack:get_name()
    local sdef = liquid_store.get_sl_def(itemname)
    local adding = ItemStack(sdef.nodename_empty) --#TODO
    -- check if above is needed (does transfer_handle.. accept string ?)
    -- also I would need to change that if I want to preserve meta from container.

    -- if itemstack is a stored liquid
    if sdef then
        return handle_newstack(itemstack, adding, player)
    else
        return itemstack
    end
end

--Function for empty buckets to call on_use... as return (so gives item)
function liquid_store.on_use_empty_bucket(itemstack, user, pointed_thing)
    --#TODO test if this is a player (is that needed ?)

    if handle_interaction(user, pointed_thing) ~= "node" then
        return
    end
    -- get node and name
    local node = minetest.get_node(pointed_thing.under)
    local name = node.name
    -- check protection
    if check_protection(pointed_thing.under, user,
                        "take ".. name) then
        return
    end

    minetest.check_for_falling(pointed_thing.under) -- install gravity
    -- get nodedef of pointed_thing
    local nodedef = minetest.registered_nodes[name]
    if not nodedef then return end -- wasn't anything we could anyways

    -- prioritize any liquid_store_fillup function
    if nodedef.ls_fillup then
        local new_wield = nodedef.ls_fillup(itemstack, user, pointed_thing.under, nodedef)
        -- if nothing given, then we know to just continue with code as per usual
        -- otherwise return new_wield
        if new_wield then return new_wield end
    end

    -- Check if pointing to a liquid source
    if on_scoop_change[name] then
        name = on_scoop_change[name]
    end
    local liquiddef = liquid_store.liquids[name]
    local storeddef = liquid_store.get_sl_def(name)

    -- pointing at a liquid
    -- NOTE: liquid was registered only in case of water and potash.
    -- NOTE: source is always be equal to name, from registration function,
    -- so I removed the "and liquiddef.source == name"
    if liquiddef then
        --[[ only remove liquid if in creative, fill stack otherwise
        --   however both only if a valid source is found]]
        local plr_creative = minimal.player_in_creative(user)
        -- get stored liquid version with that source
        local new_wield = find_stored(itemstack, name)
        -- if none, do nothing and stop
        if not new_wield then return end

        -- takes liquid and renew it (or not)
        -- force_renew requires a source neighbour
        local source_neighbor = liquiddef.force_renew
            and minetest.find_node_near(pointed_thing.under, 1,
                                        liquiddef.source)
        -- no renewing
        if not source_neighbor then
            minetest.add_node(pointed_thing.under, {name = "air"})
        end

        --[[only remove source liqui if in creative
        -- also fill stack if not in creative]]
        if not plr_creative then
            -- transfer metadata from liquid to new_wield
            new_wield = ItemStack(new_wield) -- need to convert before
            liquid_metadata(pointed_thing.under,node,new_wield)
            -- deal with the fact that we maybe had a stack when we tried to fill, to generate proper replacement
            return handle_newstack(itemstack, new_wield, user)
        end
    -- pointing at a stored liquid
    elseif storeddef then
        -- #TODO could be replaced by replace function ?
        local new_wield = find_stored(itemstack, storeddef.source)
        if not new_wield then return end -- nothing matches

        -- transfer metadata from old pot to new_wield
        new_wield = ItemStack(new_wield) -- need to convert before
        liquid_metadata(pointed_thing.under,node,new_wield)
        -- clear out pot at pos
        minimal.switch_node(pointed_thing.under,  storeddef.nodename_empty)
        -- deal with the fact that we maybe had a stack when we tried to fill, to generate proper replacement
        return handle_newstack(itemstack, new_wield, user)
    -- neither liquid nor a stored liquid
    -- non-liquid nodes will have their on_punch triggered
    elseif nodedef.on_punch then
        return nodedef.on_punch(pointed_thing.under, node, user, pointed_thing)
    end

end

--Function for filled buckets to call on_use... as return (so gives item)
function liquid_store.on_use_filled_bucket(itemstack, user, pointed_thing, dump, source, nodename_empty)
    --#TODO test if this is a player (is that needed ?)

    -- Must be pointing to node
    if handle_interaction(user, pointed_thing) ~= "node" then
        return
    end
    -- get storeddef or create a fake one
    local storeddef = liquid_store.get_sl_def(itemstack,true)
    -- get source and empty if invalid parameters or nil
    if type(source) ~= "string" then
        source = storeddef.source
    end
    if type(nodename_empty) ~= "string" then
        nodename_empty = storeddef.nodename_empty
    end

    --[[ if dump isn't specified, check storeddef.dumpable
        if result isn't a specified boolean, set to true
        (can be set to false so liquid stores such as watering cans do not dump their contents)
    ]]--
    if type(dump) ~= "boolean" then
        dump =  storeddef.dumpable
    end
    dump = type(dump) ~= "boolean" and true or dump

    -- get liquid source definition
    local sourcedef = minetest.registered_nodes[source]
    -- do not dump an unregistered source! set to false
    if not sourcedef then dump = false end

    local ppos = pointed_thing.under -- place_pos
    local buildable_to = true -- allow for replacing nil nodes

    local node = minetest.get_node_or_nil(pointed_thing.under)
    local ndef = node and minetest.registered_nodes[node.name]
    -- prioritize liquid_store_pourin function
    if ndef and ndef.ls_pourin then
        local new_wield = ndef.ls_pourin(itemstack, user, ppos, source, ndef)
        -- if nothing given, then we know to just continue with code as per usual
        -- otherwise return new_wield
        if new_wield then return new_wield end
    end
    -- made into a function as it is needed twice
    local function can_rightclick()
        -- if node definition and if player and not sneaking
        --   then do rightclick function
        if ndef and not (minetest.is_player(user)
                         and user:get_player_control().sneak) then
            -- Call on_rightclick if the pointed node defines it
            --   (do not on_rightclick for liquids or liquid_storage)
            if not (ndef.drawtype == "liquid"
                    or minimal.is_group(node.name,"liquid_storage")) then
                local on_click = minimal.on_rightclick(itemstack, user,
                                                       pointed_thing)
                if on_click ~= false then
                    -- can be returned nil, so default to itemstack
                    return on_click or itemstack
                end
            end
        end
    end

    local stored
    local click_result = can_rightclick()
    -- prioritize on_rightclick
    if click_result then
        return click_result
    -- check out my cool definition instead
    elseif ndef then
        stored = find_stored(ndef, source)
        -- don't remove liquid source nodes
        buildable_to = ndef.drawtype ~= "liquid" and ndef.buildable_to
            or false
    end
    -- check above pos (other node cannot be built to or is not an fillable pot)
    if not (buildable_to or stored) then
        pointed_thing.under = pointed_thing.above -- fixes on_rightclick

        ppos = pointed_thing.under
        ndef = minimal.get_nodedef(ppos)
        -- prioritize liquid_store_pourin function
        if ndef.ls_pourin then
            local new_wield = ndef.ls_pourin(itemstack, user, ppos, source, ndef)
            if new_wield then return new_wield end
        end
        -- don't remove liquid source nodes
        buildable_to = ndef.drawtype ~= "liquid" and ndef.buildable_to
            or false
        -- finishing touches if ndef found (verify with the found node!)
        click_result = can_rightclick()
        if click_result then
            return click_result
        elseif ndef then
            -- If pointing at a full liquid store don't dump
            dump = (not liquid_store.get_sl_def(node)) and dump or false
        end
    end
    -- we tried, can't do it
    if not (buildable_to or stored) then
        -- do not remove the bucket with the liquid
        return itemstack
    end
    -- prioritize filling up an empty container
    if stored then
        if check_protection(ppos, user, "fill up "..nodename_empty) then
            return
        end
        local def = itemstack:get_definition()
        if def.sounds and def.sounds.pour then
            minimal.sound_play(ppos, def.sounds.pour)
        end
        -- #TODO could be improved to transfer liquid meta but not pot
        minimal.switch_node(ppos, stored, {user, itemstack, pointed_thing})

        return handle_newstack(itemstack, nodename_empty, user)

        -- can replace the node
        -- dump the water ONLY if "dump" is true (if false, do not dump)
    elseif buildable_to and dump then
        if check_protection(ppos, user, "place "..source) then
            return
        end
        if sourcedef.sounds and sourcedef.sounds.place
            and sourcedef.sounds.place.name ~= "" then

            local place_sound = sourcedef.sounds.place
            minetest.sound_play(place_sound.name,
                                minimal.merge_tables(place_sound,{pos = ppos}))
        end
        minimal.switch_node(ppos, source, {user, itemstack, pointed_thing})
        minetest.check_for_falling(ppos)

        if (minimal.player_in_creative(user)) then
            return itemstack
        end

        return handle_newstack(itemstack, nodename_empty, user)
    end
end

-- used by both stored liquids and empty buckets
function liquid_store.on_place(itemstack, placer, pointed_thing)
    if handle_interaction(placer, pointed_thing) ~= "node" then
        return
    end

    local pos = pointed_thing.under
    local pos_top = pointed_thing.above

    local place_name = itemstack:get_name()
    -- no, no nils allowed
    if not minetest.registered_nodes[place_name] then return end

    local node = minetest.get_node(pos) -- grab a possible liquid if correct
    local ndef = minetest.registered_nodes[node.name] -- node definition
    local stored = find_stored(place_name, node)
    -- prevent placement of itemstack if following is a liquid or stored liquid (prevents if true)
    local isliquid = ndef.drawtype == "liquid" or stored and true or false

    -- locals can be listed like this :D
    local protected, top_protected = minetest.is_protected(pos, placer), minetest.is_protected(pos_top, placer)
    -- if player, check rightclick functionality (if not a liquid)
    if minetest.is_player(placer) then
        if type(ndef) == "table" and not placer:get_player_control().sneak
            and minetest.get_item_group(node.name,"liquid_storage") == 0
            and not isliquid then
            if ndef.on_rightclick then
                return ndef.on_rightclick(pos, node, placer, itemstack,
                                              pointed_thing)
            end
        end
    end
    -- top_node definition - check if can be placed
    local tndef = minimal.get_nodedef(pos_top)
    if not tndef then return end -- do not place if can't find node def

    if stored and not protected then
        -- if a possible liquid and an empty bucket
        return liquid_store.on_use_empty_bucket(itemstack, placer,
                                                pointed_thing)
    else
        -- verify if we can place the bucket
        if ndef.buildable_to ~= true or protected == true
             or isliquid == true then -- Can't build here,
            -- attempt to use pos_top to place above/in front of the node
            pos = (tndef.buildable_to and not top_protected) and pos_top or nil
            if not pos then return end -- Can't place bucket on either top or bottom node, give up
        end

        if not minimal.player_in_creative(placer) then
            itemstack:take_item()
        end
        -- place the bucket
        minimal.switch_node(pos, place_name, {placer, itemstack, pointed_thing})
        minetest.check_for_falling(pos)
    end

    return itemstack
end

-- register_stored_liquid
--[[ registers a bucket of liquid (hence the name, "stored liquid")
    * registers like a node, except expects 2 additional parameters:
        * empty/nodename_empty: an empty bucket of the stored liquid
        * source: the liquid that gets transferred
        * has an optional boolean value "dumpable";
          default is true
          unless source is not a registered node, then defaults to false
]]
    --[[ #TODO We could maybe only allow registration of stored liquid
    -- if container and liquid are both already registered,
    -- instead of registering them with empty def during registration
    -- if not present]]
function liquid_store.register_stored_liquid(name,def)
    assert(
        type(name) == "string",
        "liquid_store.register_stored_liquid: expected string for 'name', got "..
        type(name))
    assert(
        type(def) == "table",
        "liquid_store.register_stored_liquid: expected definition table, got "..
        type(def))

    -- add mod_origin to name
    if name:sub(1,1) == ":" then
        name = minetest.get_current_modname()..name
    elseif not name:match(":") then
        name = minetest.get_current_modname()..":"..name
    end

    -- Container ------------------------------------------------------

    -- check def.empty and set
    def.empty = def.empty or def.nodename_empty
    def.nodename_empty = nil -- deleting now useless field
    -- check container validity
    if def.empty == nil then
        core.log ("missing container to register " .. name
        .. "It will NOT be registered")
        return
    end
    local container_def = minetest.registered_nodes[def.empty]
    -- stop if no node's def for container
    assert(type(container_def) == "table",
        "liquid_store.register_stored_liquid: expected nodedef"
        .. "(could not find nodedef for empty variant of '" .. name
        .. "'. Got '"..tostring(def.empty).."' of type: "..type(def.empty)
        .. " instead")


    -- Liquid  ------------------------------------------------------
    if def.source == "" or not def.source then
        minetest.log("error", name
        ..": does not have a proper source to transfer, "
        .." will not be able to transfer liquids properly!")
    end

    -- Register stored liquid in liquid_store table
    liquid_store.stored_liquids[name] = {
        nodename = name,
        source = def.source,
        nodename_empty = def.empty,
        dumpable = def.dumpable
    }

    -- Basic definition parameters -------------------------------------

    -- stack size is 1 by default
    def.stack_max = def.stack_max or 1
    -- def.liquids_pointable is true by default, false if specified
    if def.liquids_pointable ~= false then
        def.liquids_pointable = true
    end

    -- Appearance -------

    -- specific setting to tell "use the container one"
    if def.node_box == "container"  then
        def.node_box = container_def.node_box
    end
    -- set drawtype to nodebox if node_box is provided or mesh if mesh
    def.drawtype = def.drawtype
                    or def.mesh and "mesh"
                    or def.node_box and "nodebox"
                    or "normal"

    def.paramtype = def.paramtype
                    or container_def.paramtype
                    or "light"

    -- adds a tile texture as string, ex: "tech_pot_potash.png"
    -- will add "^tech_pot_potash.png" on top of the container
    if def.add_liquid_tile then -- TODO to document
        def.tiles = table.copy(container_def.tiles)
        if not def.tiles then
            core.log ("in liquid_store.register_stored_liquid: "
            .. "missing tiles for container: " .. def.empty)
        else
            def.tiles[1] = def.tiles[1] .. "^" .. def.add_liquid_tile
        end
        -- remove def field once used
        def.add_liquid_tile = nil
    end

    -- Sounds -------

    -- get provided or use empty node's sound or node sound defaults
    def.sounds = def.sounds
                    or type(container_def.sounds) == "table"
                                    and table.copy(container_def.sounds)
                    or nodes_nature.node_sound_defaults()
    -- if set to false, sets to nil, otherwise adds pour sound
    if def.sounds.pour == false then
        def.sounds.pour = nil
    else
        def.sounds.pour =  {
                            name = "liquid_store_water_pour",
                            pitch = {0.85,1.05},
                            gain = 0.3,
                            max_hear_distance = 8
                            }
    end

    -- Groups  ---------------------------------------------------------

    -- groups are the one given in registration, or empty table if nil
    def.groups = def.groups or {}
    -- add a "liquid_storage" group
    def.groups.liquid_storage = 1

    -- inherit source groups from liquid_store tables only
    local source_def = liquid_store.liquids[def.source]
    -- if souce is not registered do it
    if not source_def then
        -- default registration (to keep ?)
            -- core.log("warning",
            --     "When registering " .. name
            --     .. ", liquid " .. def.source
            --     .. " was not registered.\n"
            --     .. "Registering with default settings")
                liquid_store.register_liquid(def.source)
    else -- else take source groups
        -- add source groups if not already present in def.groups
        for _, g in pairs(source_def.groups) do
            if not def.groups[g] then -- don't erase if present in def
                def.groups[g] = 1
            end
        end
    end

    -- inherit container groups from liquid_store tables only
    local container_groups = liquid_store.containers[def.empty]
    -- register container if not done yet (empty def table)
    if not container_groups then
        -- core.log("warning",
        --     "When registering " .. name
        --     .. ", container " .. def.empty
        --     .. " was not registered.\n"
        --     .. "Registering container with empty groups")
        -- registering with empty groups
        liquid_store.register_container(def.empty)
    else
        for _, g in pairs(container_groups) do
            -- add container groups if not already present in def.groups
            if not def.groups[g] then -- don't erase if present in def
                def.groups[g] = 1
            end
        end
    end

    -- Functions ----------------------------------------------------
    def.on_use = def.on_use or function(...)
        return liquid_store.on_use_filled_bucket(...)
    end

    def.on_place = def.on_place or function(itemstack, placer, pointed_thing)
        return liquid_store.on_place(itemstack, placer, pointed_thing)
    end

    -- remove from node definition
    def.source = nil
    def.empty = nil
    def.dumpable = nil

    minetest.register_node(name,def)
    return minetest.registered_nodes[name]
end


---------------------------------------------------------
--Register liquids
liquid_store.register_liquid(
    "nodes_nature:salt_water_source", -- source
    {
        flowing = "nodes_nature:salt_water_flowing", -- flowing
        force_renew = false, -- not renewable: avoid infinite source
        groups = {"salt_water"} -- groups list
    }
)

liquid_store.register_liquid(
    "nodes_nature:freshwater_source", -- source
    {
        flowing = "nodes_nature:freshwater_flowing", -- flowing
        force_renew = false, -- not renewable: avoid infinite source
        groups = {"freshwater"} --groups list
    }
)
--don't force renew or allows an infinite water supply exploit

-----------------------------------------------------------

-- replacement generation for recipes
--[[ generate a replacement for `input_sl` with `new_liquid`
    * `input_sl` is a string, representing a stored liquid or container
    * `new_liquid` is the replacement we want.
    * gives back empty container if `new_liquid` is nil
    * doesn't preserve metadata (yet)
]]
local function replace (input_sl, new_liquid)
    if not input_sl then
        core.log("in liquid_store.replace: no item to be replaced provided")
        return
    -- if input_sl is nor a table, nore a string, it is invalid
    elseif type(input_sl) ~= "string" then
        core.log("in liquid_store.replace: wrong type of input provided")
        return
    end

    -- process
    local sl_def = liquid_store.get_sl_def(input_sl)
    local container
    -- if not a stored liquid, is it a container ?
    if not sl_def then
        if not liquid_store.containers[input_sl] then
            core.log (input_sl .. " given is not a valid stored liquid or container")
            return
        else
            container = input_sl
        end
    else
        container = sl_def.nodename_empty
    end
    -- change liquid if needed, else return empty one
    if new_liquid then
        return find_stored(container, new_liquid)
    else
        return container
    end
end

liquid_store.replace = replace

