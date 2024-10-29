--------------------------------------------------------------------------
-- Spawn infrastructure

-- A region's spawn gate is either missing, queued, potential, or open.
-- When a player spawns in, he is sent through a vald open gate first. If
-- there is no open gate already, a potential gate is opened. If there is no
-- potential gate (the missing state) then a gate must be created rapidly
-- via the fast_gate() function.

-- After a gate is opened and player has spawned through it, a new gate
-- location is queued. 60 seconds later, the open gate is closed and the
-- queued gate becomes the region's current potential gate.

-- A potential or queued gate has been set up via finding a spawn position,
-- and emerging the area if possible.


-- Dependencies
__DEBUG__ = __DEBUG__
volcano = volcano
minimal = minimal
mapchunk_shepherd = mapchunk_shepherd
local ms = mapchunk_shepherd

local function pirnt(...) -- lol print
    local tab = {...}
    local out = ""
    for i = 1, #tab do
        out = table.concat({out, tostring(tab[i]) })
    end
    minetest.log("action", out)
end

-- Config options
local wide_spawn = minetest.settings:get_bool("exile_wide_spawn") or false

-- Load hex tools
local modpath = minetest.get_modpath("spawnex")
local dirstring, hexnum,
    hex2string, string2hex,
    hex2map, map2hex,
    get_neighbor, get_neighbors,
    distance_to_hex, hexdir_from_look_horiz = dofile(modpath.."/hex.lua")
local defhex = {0,0}

local function fallback_spawn_pos(hex)
    -- Used if we have to fallback to the hex center for some reason, eg volcano
    pirnt("fallback_spawn_pos")
    local pos = hex2map(hex)
    local vground = volcano.estimate_ground_level(pos)
    local vgl = vground or 20
    local tries = 0
    local sl local xo local zo
    repeat
        tries = tries + 1
        xo = math.random(0,600)-300 zo = math.random(0,600)-300
        sl = minetest.get_spawn_level(pos.x + xo, pos.z + zo)
    until tries == 30 or ( sl and sl > vgl )
    if sl and vgl > sl then
        sl = vgl
    end
    if not sl then -- fallback if all tries failed:
        sl = 20 -- try not to put the player underground
    end
    return vector.new(pos.x + xo, sl, pos.z + zo)
end

local badplaces = {"ocean", "mountains"}
local badbiomes = { "water"}

local function isagoodbiome(name)
    for i = 1, #badbiomes do
        if name:match(badbiomes[i]) then
            return false
        end
    end
    return true
end

local function spawn_offset(hex1, max_count)
    -- Gets a random spot in a circular field around the center of the region
    local hexctr = hex2map(hex1) -- get the center
    local tgt, d, sl, vgl
    local slcount, biomecount = 0, 0
    local count = 0 local maxcount = max_count or 20
    local axis = vector.new(0,1,0)
    repeat
        d = math.random(250,1500)
        local dist = vector.new(d,0,0)
        local maxradians = math.pi * 2
        local angle = math.random(0, maxradians*1000) / 1000 -- 0 to 6.2831 r
        local check =
            vector.round(hexctr:add(
                             vector.rotate_around_axis(dist,axis,angle)))
        sl = minetest.get_spawn_level(check.x, check.z)
        if not sl then
            slcount = slcount + 1
        else
            vgl = volcano.estimate_ground_level(check) or 0
            local chunk = ms.mapchunk_hash(check)
            local bname =
                minetest.get_biome_name(minetest.get_biome_data(
                                            vector.new(check.x,
                                                       sl or 19,
                                                       check.z)).biome)
            if not isagoodbiome(bname) then biomecount = biomecount + 1 end
            if  sl > vgl and -- not at a volcano
                not ms.contains_labels(chunk, badplaces)
            -- not a blacklisted label
                and  isagoodbiome(bname) then -- not a blacklisted biome name
                tgt = check
            end
        end
        count = count + 1
    until count >= maxcount or tgt
    if tgt then
        tgt.y = sl
    end -- apply spawn level, or return nil
    pirnt("spawn_offset ",hex2string(hex1),
          (tgt == nil and " NOT" or "    ")," FOUND - ",
          "tries/sl/biome: ", count,"/",slcount,"/",biomecount)
    return tgt
end

--------------------------------------------------------------------------
-- Gate's portal entity
local rate = 3 -- speed of open/close
local max_size = 6 -- how big it should get
local open_time = 59 -- how long to stay open
local size_change_rate = 0.05 -- frame rate of opening/closing, 20fps
local portals = {} -- find a region's portal object, [hexstring] = ObjectRef

local function delportal(object, objhex)
    if not object then return end -- portal entity was unloaded already?
    local ourhex = objhex or map2hex(object:get_pos())
    portals[hex2string(ourhex)] = nil
    object:remove()
end
local function addportal(object)
    if not object then return end -- unloaded?
    local ourhex = map2hex(object:get_pos())
    if portals[hex2string(ourhex)]
        and portals[hex2string(ourhex)] ~= object then
        -- one portal entity per hex plz
        delportal(portals[hex2string(ourhex)], ourhex)
    end
    portals[hex2string(ourhex)] = object
end

minetest.register_entity(
    "spawnex:gate",{
        initial_properties = {
            visual = "upright_sprite",
            use_texture_alpha = true,
            pointable = true,
            collides_with_objects = false,
            textures = { "spawnex_portal.png^[colorize:#4444E932",},
            visual_size = { x = 0, y = 0, z = 0},
            spritediv = { x = 1, y = 15 },
            --nametag = "GATE",
            glow = 16,
            shaded = false,
            show_on_minimap = true,
        },
        _desc = "A gate from somewhere else",
        on_activate = function(self, staticdata, dtime_s)
            if staticdata and staticdata ~= "" then
                self.timer = (tonumber(staticdata) or 0 ) + dtime_s
            else
                self.timer = 0
            end
            addportal(self.object)
        end,
        on_step = function(self, dtime, moveresult)
            if not self.init then
                self.init = true
                self.size = 0
                self.timer = self.timer or 0
                self.resend = 0
                self.timelimit = size_change_rate
                self.object:set_sprite(nil, 15, 0.05) -- 20 fps
                self.state = "opening"
            end
            if self.state == "closed" then
                delportal(self.object) return
            end
            self.timer = ( self.timer or 0 ) + dtime
            self.resend = self.resend + dtime
            if self.resend > 5 then -- every 5.0 seconds
                self.object:set_sprite(nil, 15, 0.05) -- 'cause per-client
                self.resend = 0
            end
            if self.timer < self.timelimit then return end
            self.timer = 0
            local obj = self.object
            local function change_size()
                obj:set_properties({ visual_size = { x = self.size,
                                                     y = self.size } })
            end
            if self.state == "opening" then
                self.size = self.size + dtime * rate
                if self.size >= max_size then
                    self.size = max_size
                    self.state = "open"
                    self.timelimit = open_time
                    self._gatesound = minetest.sound_play(
                        "spawnex_portal",
                        { gain = 1.0, fade = 0.2, pitch = 2.0,
                          loop = true, object = self.object }  )
                end
                change_size()
            elseif self.state == "open" then
                self.state = "closing"
                if self._gatesound then
                    minetest.sound_fade(self._gatesound, 0.5, 0)
                end
                self.timelimit = size_change_rate
            elseif self.state == "closing" then
                self.size = self.size - dtime * rate
                if self.size <= 0 then
                    self.size = 0
                    self.state = "closed"
                end
                change_size()
            end
        end,
        get_staticdata = function(self)
            return tostring(self.timer)
        end
})

--------------------------------------------------------------------------
-- Region layer

local storage = minetest.get_mod_storage()

region = {}
rgns = minetest.deserialize(storage:get_string("regions")) or {}
--[[
    { ["0:0"] = { [currentgate] = pos, ["nextgate"] = pos,
    ["open"] = true, ["gate"] = ObjRef, [..] = ... } }
]]--

local jobs = minetest.deserialize(storage:get_string("jobs")) or {}
-- jobs: could have used minetest.after, but we want to save it on restart

local function load_rgns()
    local idxstring = storage:get_string("rgn_index")
    if idxstring == "" then return end
    local idx = minetest.parse_json(idxstring) or {}
    for i = 1, #idx do
        local nm = idx[i]
        local str = storage:get_string(nm)
        rgns[nm] = minetest.parse_json(str, nil) or minetest.deserialize(str)
    end
end

local function save_rgns(hex)
    local function writeout(hx, tb)
        local str, err = minetest.write_json(tb, nil)
        if err then
            pirnt("Spawnex: Error saving region ",hx)
            pirnt("Dump of region data: ",dump(tb))
            return
        end
        storage:set_string(hx, str)
    end
    if hex then -- save just one
        writeout(hex2string(hex), rgns[hex])
    end
    local idx = {}
    for nm, dat in pairs(rgns) do
        if not hex then writeout(nm, dat) end
        table.insert(idx, nm)
    end

    storage:set_string("rgn_index", minetest.write_json(idx))
end

if rgns["0:0"] then -- Convert old regions storage format
    pirnt("Converting old region storage")
    save_rgns()
    storage:set_string("regions", nil)
else
    pirnt("Loading region storage (new format)")
    load_rgns()
end

local function save_jobs()
    storage:set_string("jobs", minetest.serialize(jobs))
end

function add_job(name, time, hex)
    pirnt("Adding job: ",name," at ",hex2string(hex))
    jobs[name.."_"..hex2string(hex)] = {
        name = name, timer = 0, finish = time, target = hex }
end

function region.get(hex) -- #TODO: add other features for regions
    local id = hex2string(hex)
    if not rgns[id] then
        rgns[id] = {}
    end
    return rgns[id]
end

local function find_gate_pos(hex, tries) -- pick a spawn position in a hex
    return spawn_offset(hex, tries or 200)
end

local function load_gate(hex) -- forceload a gate's location to prep for a spawn
    pirnt("Load gate for ",hex2string(hex))
    local def = region.get(hex)
    if def.forceloaded == true or not def.currentgate then return end
    local mb_min = vector.new(math.floor(def.currentgate.x / 16) * 16,
                              math.floor(def.currentgate.y / 16) * 16,
                              math.floor(def.currentgate.z / 16) * 16)
    local mb_max = vector.new(mb_min.x + 15, mb_min.y + 15, mb_min.z + 15)
    minetest.emerge_area(mb_min, mb_max)
    minetest.forceload_block(def.currentgate)
    def.forceloaded = true
    save_rgns(hex)
end

local function setup_gate(hex) -- create potential gate
    local def = region.get(hex)
    if not def.currentgate then
        def.currentgate = find_gate_pos(hex)
        if def.currentgate == nil then
            add_job("setup", 1, hex)
            return false
        else
            pirnt("setup new gate for ",hex2string(hex),
                  " - got: ",minetest.pos_to_string(def.currentgate))
            save_rgns(hex)
        end
        return true
    end
    return false
end

function queue_next_gate(hex) -- Set up next gate before closing current one
    local def = region.get(hex)
    if def.nextgate then return end -- already have one queued
    local candidate
    candidate = find_gate_pos(hex, 50)
    local distance = 0
    if def.currentgate and candidate then
        distance = candidate:distance(def.currentgate)
    end
    -- not too close to previous spawn, please
    if candidate == nil or distance < 400 then
        add_job("queue", 9, hex)
        return
    end
    def.nextgate = candidate
    save_rgns(hex)
end

function region.fast_gate(hex) -- No gate for this hex, make one quick!
    local gate = find_gate_pos(hex, 25) -- just 25 tries before giving up
    if not gate then
        gate = fallback_spawn_pos(hex)
    end
    local def = region.get(hex)
    def.currentgate = gate
    save_rgns(hex)
    return gate
end

local function close_gate(hex)
    local def = region.get(hex)
    local oldgate = def.currentgate
    if def.forceloaded then minetest.forceload_free_block(oldgate) end
    local static = minetest.setting_get_pos("static_spawnpoint")
    if static and ( hexnum(map2hex(static)) == hexnum(hex) ) then
        def.currentgate = static
    else
        def.currentgate = def.nextgate
    end

    def.open = false
    def.forceloaded = false
    def.nextgate = nil
    if not setup_gate(hex) then save_rgns(hex) end -- save changes if no new gate
end

local function select_hex_from(hex) -- for wide spawn
    -- Pick a valid hex within a 1-hex range, ensure there's a gate somewhere
    local neigh = get_neighbors(hex)
    table.insert(neigh, hex) -- add the middle in, too
    local open = {} -- A gate is open here, send player here first if possible
    local potentials = {} -- A gate pos has been selected
    local missing = {} -- Nothing is ready here, last resort
    local full_list = {} -- combined potentials and missing for random select
    for i = 1, #neigh do
        if #neigh[i] == 2 then -- this is a valid hex
            local def = region.get(neigh[i])
            if def.open then
                table.insert(open, neigh[i])
            elseif def.currentgate then
                table.insert(potentials, neigh[i])
                table.insert(full_list, neigh[i])
            else
                table.insert(missing, neigh[i])
                table.insert(full_list, neigh[i])
            end
        end
    end
    pirnt("select hex from ",hex2string(hex)," open: ",#open,
          " ready: ",#potentials," missing: ",#missing, " full_list: ",#full_list)
    -- Corners can have as few as two neighbors, and if they're open, #missing = 0
    if #missing > 0 then -- pick out a new gate for this area
        local selhex = missing[math.random(1, #missing)]
        pirnt("adding a new gate")
        setup_gate(selhex)
        table.insert(potentials, selhex)
    end
    if #open > 0 then
        pirnt("Selected an opened gate")
        return open[math.random(1, #open)]
    end
    for i = 1, #potentials do -- 2x chance to get potential gate
        table.insert(full_list, potentials[i])
    end
    local newgate = full_list[math.random(1, #full_list)]
    pirnt("Selected gate at ",hex2string(newgate))
    if not region.get(newgate).currentgate then -- we hit a missing gate anyway
        pirnt("And scanning it:")
        setup_gate(newgate)
    end
    return newgate
end

function region.prespawn(player, centrhx) -- Ready a spawn gate for this player
    if not player or not player:is_player() then return end
    if minetest.settings:get_bool("disable_spawnex", false) then return end
    pirnt("region prespawn")
    local meta = player and player:get_meta()
    local home = centrhx or string2hex(meta:get("exile_spawnhome")) or defhex
    local tgt = home
    if wide_spawn then
        tgt = string2hex(meta:get_string("exile_spawnat"))
            or select_hex_from(home)
    end
    local rdef = region.get(tgt)
    local gate = rdef.currentgate
    if not gate then setup_gate(tgt) end
    load_gate(tgt)
    meta:set_string("exile_spawnat", hex2string(tgt))
end

local function walkable_and_open(pos)
    local node = minetest.get_node(pos)
    if node.name == "ignore" then
        return nil
    end
    local def = minetest.registered_nodes[node.name]
    if not def or def.walkable == true then
        return false
    end
    local light = minimal.get_daylight(pos, 0.5)
    if light < 6 then -- light > 5 indicates we're probably not underground
        return false
    end
    return true
end

local function fixplayer(player, quiet)
    if not minetest.is_player(player) then return end
    if not quiet then
        pirnt("Fixplayer needed for "..player:get_player_name() )
    end
    local pos = player:get_pos()
    local function go_up()
        player:set_pos(vector.new(pos.x, pos.y + 5, pos.z))
        minetest.after(0, fixplayer, player, true)
    end
    local good = walkable_and_open(pos)
    if good == true then return end
    if good == false then
        go_up()
        return
    end
    -- Not loaded, try again
    minetest.after(0.1, fixplayer, player, true)
    return
end

function region.spawn(player)
    if not player or not player:is_player() then return end

    local function checkplayer(pos)
        local good = walkable_and_open(pos)
        if good == true then return end
        if good == false then
            fixplayer(player)
            return
        end
        -- Not loaded, try again
        minetest.after(0.1, checkplayer, player, true)
        return
    end

    pirnt("region spawn for ",player:get_player_name())
    local meta = player:get_meta()
    local spawning = meta:get_string("spawning")
    if minetest.settings:get_bool("disable_spawnex", false)
        and spawning ~= "" then -- this clause is just-in-case, may be unneeded
        local pos = minetest.string_to_pos(spawning)
        if pos:distance(vector.zero()) <  100 then -- Inside Mt. Meru!
            pos = fallback_spawn_pos(string2hex("0:0")) -- Grab a fallback spot
        end
        minetest.add_entity(vector.new(pos.x, pos.y+1.5, pos.z), "spawnex:gate")
        player:set_pos(pos)
        checkplayer(pos)
        return
    end
    local home = string2hex(meta:get("exile_spawnhome")) or defhex
    local spawnat = home
    if wide_spawn then
        spawnat = string2hex(meta:get("exile_spawnat")) or select_hex_from(home)
        meta:set_string("exile_spawnat", "") -- clear the used spawn pos
    end

    local sadef = region.get(spawnat)
    local gate = sadef.currentgate
    if not gate then
        gate = region.fast_gate(spawnat)
        sadef.currentgate = gate
        load_gate(spawnat)
    end
    sadef.open = true
    pirnt("spawn: ",hex2string(spawnat)," : ",
          minetest.pos_to_string(sadef.currentgate))
    minetest.add_entity(gate, "spawnex:gate")
    player:set_pos(gate)
    checkplayer(gate)

    -- get a new spawn location, but wait until this gate is closed!
    minetest.after(70, function() region.prespawn(player) end )
    add_job("queue", 20, spawnat)
    add_job("close", 60, spawnat)
    save_jobs()
end

if minetest.settings:get_bool("disable_spawnex", false) == true then
    return -- shouldn't need any of this
end


--------------------------------------------------------------------------
-- Player tracking and update jobs

local timer = 0

local homecache = {}
local savejobs = false

local func = -- can't serialize actual functions, so correlate with string name
    { ["queue"] = queue_next_gate, ["close"] = close_gate,
        ["setup"] = setup_gate, }

-- how far you need to get from center of home to new home
local maxdist = 2750 -- 2000 to the edge of the next hex, 1250 from its center
local maxdist_wide = maxdist + 4000 -- one extra hex out, drags center behind
local shift = {} -- stores midway region, in wide spawn. for this ^^

local function player_moved_to_new_region(player, pname, ppos, home)
    -- If a player moves far enough from his home region, we need to set
    --  the new region as his home, for regular spawn. Wide spawn will
    --  drag a "shift" hex out from home, and then set it when the player
    --  is far enough from the shift hex.
    local saveout = false
    local newhex = map2hex(ppos)
    local disthome = distance_to_hex(ppos, home)
    if  disthome > maxdist then
        if not wide_spawn then
            homecache[pname] = newhex
            saveout = true
        elseif not shift[player] then
            shift[player] = newhex -- this is important if player teleported
        else -- wide spawn, and we have a shift region already; what do?
            if disthome > maxdist_wide then -- far out, move the player's home
                pirnt(pname..": updated home to: ",hex2string(shift[player]))
                homecache[pname] = shift[player]
                shift[player] = nil
                saveout = true
            elseif disthome < maxdist then -- came back home, so remove shift
                shift[player] = nil
            elseif ( disthome < maxdist / 2 and -- circled around, so change shift
                     distance_to_hex(shift[player]) > maxdist ) then
                shift[player] = newhex
            end
        end
    end
    return saveout
end

local function spawnex_global(dtime)
    for nm, dat in pairs(jobs) do -- run jobs
        dat.timer = dat.timer + dtime
        if dat.timer > dat.finish then
            pirnt("Spawnex running job:",dat.name," at ",hex2string(dat.target))
            func[dat.name](dat.target)
            jobs[nm] = nil
            savejobs = true
        end
    end
    if savejobs == true then save_jobs() savejobs = false end

    timer = timer + dtime
    if timer > 27 then
        timer = 0 -- Check for players who have moved
        for _, player in pairs(minetest.get_connected_players()) do
            local pname = player:get_player_name()
            local home = homecache[pname]
            local meta -- only read it if we need it, and hold it for later
            local saveout = false
            if not home then
                meta = player:get_meta()
                home = string2hex(meta:get_string("exile_spawnhome"))
                if not home then
                    home = defhex -- default for new players
                    saveout = true
                end
                homecache[pname] = home
            end
            local ppos = player:get_pos()
            local dfrom = distance_to_hex(ppos, home)
            if dfrom > maxdist then -- we're well out of our home region
                local moved = player_moved_to_new_region(player, pname,
                                                                ppos, home)
                saveout = saveout or moved
                home = homecache[pname] -- in case we updated
            end
            if saveout then
                if not meta then meta = player:get_meta() end
                meta:set_string("exile_spawnhome", hex2string(home))
                meta:set_string("exile_spawnat", "")
                pirnt(pname..": home hex changed, selecting spawn pos")
                region.prespawn(player, home)
            end
        end
    end
end
minetest.register_globalstep(spawnex_global)

--------------------------------------------------------------------------
-- Shutdown
minetest.register_on_shutdown(function()
        save_jobs()
        save_rgns()
end)

--------------------------------------------------------------------------
-- Startup and new player setup

local function spawnex_startup()
    local static = minetest.setting_get_pos("static_spawnpoint")
    if static then
        defhex = map2hex(static)
        rgns[hex2string(defhex)] = { ["currentgate"] = static }
        return
    end
    if wide_spawn then -- Check area, ensure there's a gate set up
        pirnt("Wide spawn enabled, checking default spawn area for gates")
        select_hex_from(defhex)
        return
    end
    -- not wide_spawn? check defhex only, set up a gate if needed
    if not rgns[hex2string(defhex)] then
        setup_gate(defhex)
    end
end
minetest.register_on_mods_loaded(function()
        minetest.after(0.1,spawnex_startup)
end)

minetest.register_on_joinplayer(function(player)
        local pname = player:get_player_name()
        local meta = player:get_meta()
        local home = string2hex(meta:get_string("exile_spawnhome"))
        if not home then
            pirnt("Player "..pname.." joined without a home region")
            home = defhex
            meta:set_string("exile_spawnhome", hex2string(home))
        end -- default for new players
        homecache[pname] = home
end)

minetest.register_on_dieplayer(function(player)
        pirnt("Player "..player:get_player_name()..
              " died, calling region.prespawn")
        region.prespawn(player)
end)

--------------------------------------------------------------------------
-- Commands

minetest.register_chatcommand(
    "fixplayer",{
        description = "Fix a player who is stuck underground,"..
            " probably from the use of /fbspawn",
        params = "<playername>",
        privs = "server",
        func = function(name,param)
            local player
            if param then
                player = minetest.get_player_by_name(param)
            end
            if not player then
                player = minetest.get_player_by_name(name)
            end
            fixplayer(player)
        end
})

--------------------------------------------------------------------------
-- Debug commands

if not __DEBUG__ then return end

minetest.register_chatcommand(
    "d2hex",{
        description = "Find the distance from your position to the center"..
            "of a region",
        params = "<Hx:Hz>",
        --privs = "server",
        func = function(name,param)
            local hex = string2hex(param)
            if not hex then
                return false, "Invalid parameters, must be <hex #, x> <hex #, z>"
            end
            local ppos = minetest.get_player_by_name(name):get_pos():round()
            local hexpos = hex2map(hex)
            local dist = vector.distance(ppos, hexpos)
            return true, "Distance: "..tostring(dist)
        end
})

minetest.register_chatcommand(
    "checkhex",{
        description = "Find the distance to the center of your (or a player's) current region",
        params = "<playername, optional>",
        --privs = "server",
        func = function(name,param)
            local player = minetest.get_player_by_name(param)
                or minetest.get_player_by_name(name)
            local ppos = player:get_pos():round()
            local nearest = map2hex(ppos)
            local num = hexnum(nearest)
            return true, "hex #"..tostring(num).." "..hex2string(nearest)..
                " center is "..tostring(distance_to_hex(ppos, nearest))..
                " nodes away."
        end
})

minetest.register_chatcommand(
    "hexneighbors",{
        description = "List neighboring regions",
        --privs = "server",
        func = function(name,param)
            local ppos = minetest.get_player_by_name(name):get_pos():round()
            local nearest = map2hex(ppos)
            local wontyoube = get_neighbors(nearest)
            local num = hexnum(nearest)
            minetest.chat_send_player(name, "You are in hex #"..tostring(num)
                                      ..": "..hex2string(nearest))
            local liststring = "Neighbors: "
            for dir, hex in pairs(wontyoube) do
                liststring = liststring.."\n "..dirstring[dir][2]..": "..
                    hex2string(hex).." -- "..
                    tostring(distance_to_hex(ppos, hex))
            end
            return true, liststring
        end
})

minetest.register_chatcommand(
    "hexlook",{
        --privs = "server",
        description = "Name the neighboring region that you're looking towards",
        func = function(name,param)
            local player = minetest.get_player_by_name(name)
            local look = player:get_look_horizontal()
            local ppos = player:get_pos()
            local dir = hexdir_from_look_horiz(look)
            local phex = map2hex(ppos)
            local hex = get_neighbor(phex, dir)
            return true, "You are facing "..dirstring[dir][1]..", towards hex "..
                hex2string(hex)
        end
})

minetest.register_chatcommand(
    "hexportu",{
        privs = "server",
        description = "Teleport player to the specified region's hex",
        params = "<player> <Hx:Hz>",
        func = function(name,param)
            local pname, tgtstr = unpack(param:split(" ", false, 1))
            print("Got ",pname," and ",tgtstr)
            local player = minetest.get_player_by_name(pname:gsub(",",""))
            local tgt = string2hex(tgtstr)
            if not tgt or not player then
                return false, "Invalid parameters, must be playername, <hex #, x> <hex #, z>"
            end
            local ppos = player:get_pos():round()
            local spos = spawn_offset(tgt)
            if spos == nil then return false, "can't find a valid pos" end
            player:set_pos(spos)
            return true, pname.." hexported: "..
                minetest.pos_to_string(ppos).." -> "..
                minetest.pos_to_string(spos)
        end
})
minetest.register_chatcommand(
    "hexport",{
        privs = "server",
        description = "Teleport to the specified region's hex",
        params = "<Hx:Hz>",
        func = function(name,param)
            local tgt = string2hex(param)
            if not tgt then
                return false, "Invalid parameters, must be <hex #, x> <hex #, z>"
            end
            local ppos = minetest.get_player_by_name(name):get_pos():round()
            local spos = spawn_offset(tgt)
            if spos == nil then return false, "can't find a valid pos" end
            minetest.get_player_by_name(name):set_pos(spos)
            return true, minetest.pos_to_string(ppos).." -> "..
                minetest.pos_to_string(spos)
        end
})

minetest.register_chatcommand(
    "spawnlevel",{
        description = "Get results of get_spawn_level() at your position",
        --privs = "server",
        func = function(name,param)
            pirnt("Checking SL")
            local player = minetest.get_player_by_name(name)
            local ppos = player:get_pos()
            local sl = minetest.get_spawn_level(ppos.x, ppos.z)
            pirnt("SPAWN LEVEL: ",sl)
            pirnt("VOLCANO LEVEL: ",volcano.estimate_ground_level(ppos))
            return true, sl
        end
})

minetest.register_chatcommand(
    "biome",{
        --privs = "server",
        description = "Name the biome you're standing in",
        params = "",
        func = function(name,param)
            local player = minetest.get_player_by_name(name)
            local ppos = player:get_pos()
            local dat = minetest.get_biome_data(ppos)
            return true, minetest.get_biome_name(dat.biome)
        end
})
minetest.register_chatcommand(
    "hexstat",{
        description = "Get stats for your current region, or specify one",
        params = "none or <Hx:Hz>",
        privs = "server",
        func = function(name,param)
            local player = minetest.get_player_by_name(name)
            local ppos = player:get_pos()
            local hex = string2hex(param) or map2hex(ppos)
            local r = region.get(hex)
            local jobnames = ""
            for nm, job in pairs(jobs) do
                if job.target == hex then
                    jobnames = jobnames .. nm .. ", "
                end
            end
            jobnames = jobnames ~= "" and "\nJobs: "..jobnames or ""
            if not r.currentgate then
                return true, "unloaded, "..jobnames
            end
            return true, "Hex at "..hex2string(hex).." : \n"..
                (r.currentgate and "Current gate: "..
                 minetest.pos_to_string(r.currentgate) or "No current gate")..
                (r.forceloaded and "[Loaded]" or "")..
                (r.open and "[Open]" or "")..
                (r.nextgate and "\nNext gate: "..
                 minetest.pos_to_string(r.currentgate) or "")..
                jobnames
        end
})

minetest.register_chatcommand(
    "myhex",{
        description = "List the region you will spawn in next",
        --privs = "server",
        func = function(name,param)
            local player = minetest.get_player_by_name(name)
            local meta = player:get_meta()
            return true, "Your hex home is :"..
                meta:get_string("exile_spawnhome")..
                " Wide spawn is "..(wide_spawn and "enabled"..
                                    " and you will spawn in "..
                                    (meta:get("exile_spawnat") or "??")
                                    or "disabled")
        end
})

minetest.register_chatcommand(
    "newgate",{
        privs = "server",
        description = "Create a new gate in the specified region",
        params = "<Hx:Hz>",
        func = function(name,param)
            local hex = string2hex(param)
            if not hex then
                return false, "Invalid parameters, must be <hex #, x> <hex #, z>"
            end
            close_gate(hex)
            setup_gate(hex)
            local pos = region.get(hex).currentgate
            if not pos then
                return false, "failed to set up gate for "..param
            end
            return true,
                "Set up new gate for "..hex2string(hex)..
                " at ".. minetest.pos_to_string(pos)
        end
})

minetest.register_chatcommand(
    "fbspawn",{
        description = "Test the last-resort fallback spawn system",
        privs = "server",
        func = function(name,param)
            local tgt = string2hex(param)
            if not tgt then
                return false, "Invalid parameters, must be <hex #, x> <hex #, z>"
            end
            local player = minetest.get_player_by_name(name)
            local ppos = player:get_pos():round()
            local spos = fallback_spawn_pos(tgt)
            if spos == nil then return false, "can't find a valid pos" end
            player:set_pos(spos)
            return true, minetest.pos_to_string(ppos).." -> "..
                minetest.pos_to_string(spos)
        end
})

minetest.register_chatcommand(
    "toggleloadgate",{
        description = "Load or unload the gate for a specified region",
        params = "<Hx:Hz>",
        privs = "server",
        func = function(name,param)
            local player = minetest.get_player_by_name(name)
            local ppos = player:get_pos()
            local hex = string2hex(param) or map2hex(ppos)
            local r = region.get(hex)
            if r.currentgate == nil then
                return false, "No gate for this hex"
            end
            if r.forceloaded then
                close_gate(hex)
                return true, "Unloaded gate"
            else
                load_gate(hex)
                return true, "Loaded gate"
            end
        end
})

minetest.register_chatcommand(
    "spawnex_inspect",{
        description = "Dumps all data concerning spawnex to log",
        params = "storage",
        privs = "server",
        func = function(name,param)
            if param ~= "storage" then
                pirnt("--- Regions (rgns) ---")
                pirnt(dump(rgns))
                pirnt("--- Job queue (jobs) ---")
                pirnt(dump(jobs))
            else
                pirnt("--- Storage (rgn_index) ---")
                print(storage:get_string("rgn_index"))
                pirnt("--- Storage (jobs) ---")
                print(dump(minetest.deserialize(storage:get_string("jobs"))))
            end
        end
})
