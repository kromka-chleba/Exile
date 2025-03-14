-- This file contains quick blocks of code that can be enabled for debugging
--
--
exile = exile
exile.debug = exile.debug or {
                             }

minimal = minimal

__DEBUG__ = minetest.settings:get_bool("exile_debug")

function exile.debug.print(message)
    if __DEBUG__ then
        minetest.log('warning', message)
    end
end

function exile.debug.dump_nodedef_params(params, filter)
    if type(params) == 'string' then
        params = { params }
    end
    for node,def in pairs(minetest.registered_nodes) do
        if string.find(node,filter,1) then
            for _,param in ipairs(params) do
                minetest.log('warning', "Node: "..node.."  "..param..": "
                             ..dump(def[param]))
            end
        end
    end
end

function exile.debug.log_to_world(message, filename)
    if __DEBUG__ then
        local wpath = minetest.get_worldpath()
        local wname = wpath:match( "([^/\\]+)$" )
        filename = filename or (wname..'_debug.log')  -- default val
        local filespec = wpath..'/'..filename
        local file, err = io.open( filespec, 'a')
        if (err ~= nil) then
            return
        end
        file:write( message )
        file:flush()
        file:close()
    end
end

if __DEBUG__ then
    minetest.register_chatcommand(
        "itemmeta", {
            params = "<none>",
            description = "Prints the meta table of the currently wielded item",
            privs = {},
            func = function(name, param)
                local plyr = minetest.get_player_by_name(name)
                local witem = plyr:get_wielded_item()
                print(dump2(witem:get_meta():to_table()))
            end
    })
    minetest.register_chatcommand(
        "nodemeta", {
            params = "<none>",
            description = "Prints the meta table of the currently pointed node",
            privs = {},
            func = function(name, param)
                local pointed_thing = minimal.get_pointed_thing(name)
                if not pointed_thing or not pointed_thing.type == "node" then
                    return
                end
                local nodename = minetest.get_node(pointed_thing.under).name
                local meta = minetest.get_meta(pointed_thing.under)
                print(nodename," - ",dump2(meta:to_table()))
            end
    })
    minetest.register_chatcommand(
        "plyrmeta", {
            params = "<none>",
            description =
                "Prints the meta table of the pointed player, or yourself",
            privs = {},
            func = function(name, param)
                local myself = minetest.get_player_by_name(name)
                local target
                local pointed_thing = minimal.get_pointed_thing(name,nil,true)
                if ( pointed_thing and pointed_thing.type == "player" ) then
                    target = pointed_thing.ref
                else
                    target = myself
                end
                --local nodename = minetest.get_node(pointed_thing.under).name
                --local meta = minetest.get_meta(pointed_thing.under)
                if target then
                    print(dump2(target:get_meta():to_table().fields))
                else
                    return false, "could not get target"
                end
            end
    })
    minetest.register_chatcommand(
        "itemdef", {
            params = "<none>",
            description = "Prints the definition of the currently wielded item",
            privs = {},
            func = function(name, param)
                local plyr = minetest.get_player_by_name(name)
                local witem = plyr:get_wielded_item()
                print(dump2(minetest.registered_items[witem:get_name()]))
            end
    })
end


minetest.register_on_mods_loaded(function()
        if __DEBUG__ ==  false then
            -- Funky debug command from naturalslopeslib, get rid of it
            minetest.unregister_chatcommand("updshape")
            -- Unneeded from player_monoids
            minetest.unregister_chatcommand("test_monoids")
            -- Debugging for volcano modding
            minetest.unregister_chatcommand("findvolcano")
        end
end)
