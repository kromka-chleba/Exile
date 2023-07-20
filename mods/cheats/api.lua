local function math_clamp(num,min,max) -- math.clamp implementation from my function library
  -- PARAMETERS: num;"number" - number to be clamped | min;"number" - minimum number that 'num' can be | max;"number" - maximum number that 'num' can be
  -- RETURNS: number - 'num' that is clamped (or not if 'num' is between 'min' and 'max')
  -- FUNCTION: clamps a specified number between a min & max
  ------------------------------------------------------------------------------------------------------------------
  
  if (type(num) == "number" and type(min) == "number" and type(max) == "number") then -- if num, min, and max are numbers then
    if (min > max) then -- if programmer puts max number in place of minimum number... don't punish them for it
      local temp = min -- create a temporary value so that 'min' can be stored
      min = max -- set 'min' to 'max'
      max = temp -- set 'max' to the temporary value
    end
    
    if (num < min) then -- if number is smaller than 'min' then
      num = min -- set number to 'min'
    elseif (num > max) then -- if number is greater than 'max' then
      num = max -- set number to 'max'
    end
    -- "if elseif" statement because if it's lower than minimum then it's obviously not going to be greater than maximum and vice versa (and DO NOT clamp if the number is between min and max)
    
    return num -- return the provided number to clamp
  else -- if the programmer doesn't mention all the parameters ):<
    if (type(num) ~= "number") then -- time to ERROR
      error("math.clamp: no number provided to be clamped")
    elseif (type(min) ~= "number") then
      error("math.clamp: no minimum number provided for clamping")
    elseif (type(max) ~= "number") then
      error("math.clamp: no maximum number provided for clamping")
    end
  end
end

-- INTEGRATED MATH_CLAMP() FROM TPH_LIB /\ (my personal function library :D - TPH aka "TubberPupperHusker")

-- PRIVILEGES

minetest.register_privilege("cheats",{ -- cheatser cheaty jackson
    description = "Access to debug functions & menu",
    
    give_to_singleplayer = false,
    
    give_to_admin = false,
  }
)

-- PRIVILEGES

-- BASE FUNCTIONS

function cheats.set_health(plr,hp) -- HEALTH MODIFICATION
  if (type(plr) == "string") then
    plr = minetest.get_player_by_name(plr)
  end
  
  if (minetest.is_player(plr) ~= true) then
    return false,"No player specified or not an active player"
  end
  
  if (type(hp) ~= "number") then
    return false,"HP not a number"
  else
    hp = math_clamp(hp,0,20)
    
    hp = math.ceil(hp) -- maintain integerssss
  end
  
  local plrhp = plr:get_hp()
  
  if (plrhp > 0) then
    -- if player alive
    plr:set_hp(hp)
    return true,"Player's health successfully set to "..tostring(hp)
  else
    -- schrodinger would be proud
    return false,"Player is dead"
  end
end

function cheats.set_energy(plr,enrg) -- ENERGY MODIFICATION
  if (type(plr) == "string") then
    plr = minetest.get_player_by_name(plr)
  end
  
  if (minetest.is_player(plr) ~= true) then
    return false,"No player specified or not an active player"
  end
  
  if (type(enrg) ~= "number") then
    return false,"Enrg not a number"
  else
    enrg = math_clamp(enrg,0,1000)
    
    enrg = math.ceil(enrg)
  end
  
  local plrhp = plr:get_hp()
  local plrmeta = plr:get_meta()
  
  if not (plrmeta:get("energy")) then
    return false,"Player has no 'Energy' meta"
  end
  
  if (plrhp > 0) then
    plrmeta:set_int("energy",enrg)
    return true,"Player's energy successfully set to "..tostring(enrg)
  else
    return false,"Player is dead"
  end
end

function cheats.set_hunger(plr,hng) -- HUNGER MODIFICATION
  if (type(plr) == "string") then
    plr = minetest.get_player_by_name(plr)
  end
  
  if (minetest.is_player(plr) ~= true) then
    return false,"No player specified or not an active player"
  end
  
  if (type(hng) ~= "number") then
    return false,"Hng not a number"
  else
    hng = math_clamp(hng,0,1000)
    
    hng = math.ceil(hng)
  end
  
  local plrhp = plr:get_hp()
  local plrmeta = plr:get_meta()
  
  if not (plrmeta:get("hunger")) then
    return false,"Player has no 'Hunger' meta"
  end
  
  if (plrhp > 0) then
    plrmeta:set_int("hunger",hng)
    return true,"Player's hunger successfully set to "..tostring(hng)
  else
    return false,"Player is dead"
  end
end

function cheats.set_thirst(plr,thrst) -- THIRST MODIFICATION
  if (type(plr) == "string") then
    plr = minetest.get_player_by_name(plr)
  end
  
  if (minetest.is_player(plr) ~= true) then
    return false,"No player specified or not an active player"
  end
  
  if (type(thrst) ~= "number") then
    return false,"Thrst not a number"
  else
    thrst = math_clamp(thrst,0,100)
    
    thrst = math.ceil(thrst)
  end
  
  local plrhp = plr:get_hp()
  local plrmeta = plr:get_meta()
  
  if not (plrmeta:get("thirst")) then
    return false,"Player has no 'Thirst' meta"
  end
  
  if (plrhp > 0) then
    plrmeta:set_int("thirst",thrst)
    return true,"Player's thirst successfully set to "..tostring(thrst)
  else
    return false,"Player is dead"
  end
end

function cheats.set_temp(plr,temp) -- TEMPERATURE MODIFICATION
  if (type(plr) == "string") then
    plr = minetest.get_player_by_name(plr)
  end
  
  if (minetest.is_player(plr) ~= true) then
    return false,"No player specified or not an active player"
  end
  
  if (type(temp) ~= "number") then
    return false,"Temp not a number"
  else
    temp = math_clamp(temp,0,100) -- 100C is boiling point, why any higher? you dead (0 C is freezing point, why any lower? you dead)
    
    temp = math.ceil(temp)
  end
  
  local plrhp = plr:get_hp()
  local plrmeta = plr:get_meta()
  
  if not (plrmeta:get("temperature")) then
    return false,"Player has no 'Temperature' meta"
  end
  
  if (plrhp > 0) then
    plrmeta:set_int("temperature",temp)
    return true,"Player's temperature successfully set to "..tostring(temp)
  else
    return false,"Player is dead"
  end
end


--[[
-- INCOMPLETE
function cheats.node_properties(pos)
  local nodestats
  if (type(pos) == "string") then
    local nodestats = minetest.registered_nodes[pos]
    
    if (type(nodestats) ~= "table") then
      pos = minetest.string_to_pos(pos)
    end
  end
end
--]]

-- BASE FUNCTIONS



-- COMMANDS RAW

local function sethealthcmd(name,param) -- HEALTH COMMAND FUNCTION
  local params = param:split(" ")
  
  local health
  
  if not (minetest.settings:get_bool("enable_damage")) then
    return false,"Damage disabled"
  end
  
  if (type(params) ~= "table") then
    return false
  end
  
  if (type(params[1]) == "string") then
    health = string.match(params[1],"%p*%d+") -- "%p" refers to all punctuation, "%d" refers to all numbers. The "*" operator means it can get 0 up to all punctuation symbols, the "+" means it can get 1 up to all numbers (google "string magic" or "string patterns")
    health = tonumber(health)
    
    if (string.lower(params[1]) == "full") then
      health = 20
    end
    
    if (type(health) ~= "number") then
      return false,"'Health' parameter not a number!"
    end
  else
    return false,"'Health' parameter empty!"
  end
  
  if (type(params[2]) == "string") then
    -- if plr specified
    return cheats.set_health(params[2],health)
  else
    -- if no plr specified then go for self
    return cheats.set_health(name,health)
  end
end

local function setenergycmd(name,param) -- ENERGY COMMAND FUNCTION
  local params = param:split(" ")
  
  if (type(params) ~= "table") then
    return false
  end
  
  local energy
  
  if (type(params[1]) == "string") then
    energy = string.match(params[1],"%p*%d+")
    energy = tonumber(energy)
    
    if (string.lower(params[1]) == "full") then
      energy = 1000
    end
    
    if (type(energy) ~= "number") then
      return false,"'Energy' parameter not a number!"
    end
  else
    return false,"'Energy' parameter empty!"
  end
  
  if (type(params[2]) == "string") then
    -- if plr specified
    return cheats.set_energy(params[2],energy)
  else
    -- if no plr specified then go for self
    return cheats.set_energy(name,energy)
  end
end

local function sethungercmd(name,param) -- HUNGER COMMAND FUNCTION
  local params = param:split(" ")
  
  if (type(params) ~= "table") then
    return false
  end
  
  local hunger
  
  if (type(params[1]) == "string") then
    hunger = string.match(params[1],"%p*%d+")
    hunger = tonumber(hunger)
    
    if (string.lower(params[1]) == "full") then
      hunger = 1000
    end
    
    if (type(hunger) ~= "number") then
      return false,"'Hunger' parameter not a number!"
    end
  else
    return false,"'Hunger' parameter empty!"
  end
  
  if (type(params[2]) == "string") then
    -- if plr specified
    return cheats.set_hunger(params[2],hunger)
  else
    -- if no plr specified then go for self
    return cheats.set_hunger(name,hunger)
  end
end

local function setthirstcmd(name,param) -- THIRST COMMAND FUNCTION
  local params = param:split(" ")
  
  if (type(params) ~= "table") then
    return false
  end
  
  local thirst
  
  if (type(params[1]) == "string") then
    thirst = string.match(params[1],"%p*%d+")
    thirst = tonumber(thirst)
    
    if (string.lower(params[1]) == "full") then
      thirst = 100
    end
    
    if (type(thirst) ~= "number") then
      return false,"'Thirst' parameter not a number!"
    end
  else
    return false,"'Thirst' parameter empty!"
  end
  
  if (type(params[2]) == "string") then
    -- if plr specified
    return cheats.set_thirst(params[2],thirst)
  else
    -- if no plr specified then go for self
    return cheats.set_thirst(name,thirst)
  end
end

local function settempcmd(name,param) -- TEMPERATURE COMMAND FUNCTION
  local params = param:split(" ")
  
  if (type(params) ~= "table") then
    return false
  end
  
  local temp
  
  if (type(params[1]) == "string") then
    temp = string.match(params[1],"%p*%d+")
    temp = tonumber(temp)
    
    if (string.lower(params[1]) == "normal" or string.lower(params[1]) == "nm") then
      temp = 37
    end
    
    if (type(temp) ~= "number") then
      return false,"'Temp' parameter not a number!"
    end
  else
    return false,"'Temp' parameter empty!"
  end
  
  if (type(params[2]) == "string") then
    -- if plr specified
    return cheats.set_temp(params[2],temp)
  else
    -- if no plr specified then go for self
    return cheats.set_temp(name,temp)
  end
end

-- COMMANDS RAW

-- COMMANDS

minetest.register_chatcommand("set_health",{
    params = "<health (0-20) | 'full'> [<player>]",
    
    description = "Sets the health of the local player. If 'player' is specified, then the player that was chosen will have their health changed. Requires 'cheats' privilege. Optional 'full' for setting to full capacity",
    
    privs = {cheats = true},
    
    func = function(name,param)
      return sethealthcmd(name,param)
    end,
})

minetest.register_chatcommand("set_energy",{
    params = "<energy (0-1000 | 'full')> [<player>]",
    
    description = "Sets the energy of the local player. If 'player' is specified, then the player that was chosen will have their energy changed. Requires 'cheats' privilege. Optional 'full' for setting to full capacity",
    
    privs = {cheats = true},
    
    func = function(name,param)
      return setenergycmd(name,param)
    end,
})

minetest.register_chatcommand("set_hunger",{
    params = "<hunger (0-1000 | 'full')> [<player>]",
    
    description = "Sets the hunger of the local player. If 'player' is specified, then the player that was chosen will have their hunger changed. Requires 'cheats' privilege. Optional 'full' for setting to full capacity",
    
    privs = {cheats = true},
    
    func = function(name,param)
      return sethungercmd(name,param)
    end,
})

minetest.register_chatcommand("set_thirst",{
    params = "<thirst (0-100 | 'full')> [<player>]",
    
    description = "Sets the thirst of the local player. If 'player' is specified, then the player that was chosen will have their thirst changed. Requires 'cheats' privilege. Optional 'full' for setting to full capacity",
    
    privs = {cheats = true},
    
    func = function(name,param)
      return setthirstcmd(name,param)
    end,
})

minetest.register_chatcommand("set_bodytemp",{
    params = "<temp (0-100 | 'normal'|'nm')> [<player>]",
    
    description = "Sets the body temperature of the local player. If 'player' is specified, then the player that was chosen will have their body temperature changed. Requires 'cheats' privilege. Optional 'normal'|'nm' for setting to normal temperature (37C)",
    
    privs = {cheats = true},
    
    func = function(name,param)
      return settempcmd(name,param)
    end,
})

-- COMMANDS
