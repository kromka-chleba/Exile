-- deals with how core.is_protected is handled

minetest = minetest
core = core

--Basic protection support
local old_is_protected = minetest.is_protected
function minetest.is_protected(pos, name, pos_meta)
    -- custom userdata or tables with get_player_name() permitted
    name = type(name) == "string" and name
        or (type(name) == "userdata"
            or type(name) == "table")
        and name.get_player_name and name:get_player_name()
    if type(name) ~= "string" then
        -- nil things can't touch stuff
        return true
    end
    -- you can specify the meta as third argument
    pos_meta = type(pos_meta) == "userdata" and pos_meta
        or minetest.get_meta(pos)
    local owner = pos_meta:get_string("owner") -- original protector of node
    local bypass = minetest.check_player_privs(name, "protection_bypass")
    -- check if owner is nil, owner is equal to name, or bypass,
    --   otherwise assume no access (false)
    local access = ( owner == ""
                     or owner == name
                     or bypass )
        or false
    -- not the owner, check if there's an access_list
    --   and if they're on the VIP list
    if not access then
        local access_list = pos_meta:get_string("access_list")
        -- if access_list, then parse its json
        access_list = access_list ~= "" and minetest.parse_json(access_list)
            or nil
        if access_list then
            for _,granted in ipairs(access_list) do
                if name == granted then
                    access = true
                    break
                end
            end
        end
    end

    -- no access, is protected
    if not access then
        return true
    end
    -- minetest's old protection always returns false so this is pointless...
    return old_is_protected(pos, name, pos_meta)
end