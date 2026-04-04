local modpath=minetest.get_modpath('exile_game')
local S = EXILE.S

local f = io.open(modpath.."/currentrevision.txt")
local rev
if f then
    rev = f:read()
    f:close()
end
if rev then
    core.log("action", "Found current revision file: "..rev)
    core.register_chatcommand(
        "version", {
            description = S("Display the current git revision"),
            func = function(name, param)
                core.chat_send_player(name,
                                      S("This server is currently running"..
                                        " git revision")..":\n "..rev)
            end
    })
end
