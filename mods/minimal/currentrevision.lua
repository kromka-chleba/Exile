local modpath=minetest.get_modpath('minimal')
minimal = minimal
local S = minimal.S

local f = io.open(modpath.."/currentrevision.txt")
local rev
if f then
    rev = f:read()
    f:close()
end
if rev then
    minetest.log("action", "Found current revision file: "..rev)
    minetest.register_chatcommand(
        "version", {
            description = S("Display the current git revision"),
            func = function(name, param)
                minetest.chat_send_player(name,
                                          S("This server is currently running"..
                                            " git revision")..":\n "..rev)
            end
    })
end
