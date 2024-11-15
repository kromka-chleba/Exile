-- shelter stage code

-- This stage handles differently from the others, without using triggers
--  other than enter/exit, and it calls the mapchunk shepherd to show off
--  the seasons.

local track = {} -- players in the stage

local function enter(player, name, offset)
end
local function exit(player, name, offset)
end

return enter, exit
