player_api = player_api

local states = {} -- table of all defined or registered states
local playerstates = {} -- holds all player state objects, indexed by pname
-- { playername = pstate }

local S = minetest.get_translator("player_api")
local health_S = minetest.get_translator("health")


--[[
    State definition table: {
    mod = "health" -- #TODO: can be specified when called: add("health:fever")
    name = "fever", -- but can just call "fever" for first match
    priority = 3, -- def display priority: 1 = info, 2 = minor, 3 = major
    -- negative priority states will not be saved to meta
    -- optional entries below
    label = _S("Fever"), -- Text label (translation string) for non-invisible states, "-" for sev only
    id = 1 -- numeric id, unique count per mod
    raise = func(), -- if exists, called when progress counter exceeds threshold
    lower = func(), -- ^^, when progress counter goes below a threshold point
    clear = func(), -- ^^, called when the state is cleared
    on_timer = func(),

    severity = 0 -- set one default severity for this state, or use progress:

    threshold = {  -- progress counter's upper limit for each stage, from 0
    [0] = 20, 40, 60, 80 -- need not be 0-100, but must be increasing values
    }
    severity_txt = { -- text labels (translation strings), nil entries will just be blank
    [0] = _S("(who cares)"), _S("(mild)"), _S("(moderate)"), _S("(severe)"), _S("(extreme)")
    } -- (Follows threshold levels, ie "who cares" is 0-20. "extreme" is 81+)
]]--


function player_api.register_state(state_table)
    states[state_table.name] = state_table
end

local pstate = { -- state query/control object, one per player
    playername = nil,
    player = nil,
    time_since_saved = 0,
    list = { -- states currently active, stored values:
        -- ["name"] = { progress = 0/nil, severity = 0/nil,
        --              timer = 0/nil, priority = 0/nil, label = "" }

        -- Must have either a progress meter or a severity
        --
        -- display will use the definition's priority as default, define it here
        --  to override ; "label = " can also override definition's label

        -- any custom fields from outside Exile should start with _
    }
}


local function blank_states(player, pname)
    local st = table.copy(pstate)
    st.player = player
    st.playername = pname
    playerstates[pname] = st
end

local function load_states(player, pname)
    -- Load saved states on rejoin, or else create blank object
    blank_states(player, pname)
end

function player_api.get_state_by_name(playername, modname)
    local state = playerstates[playername]
    if not state then
        minetest.log('error', "No state found for "..playername)
        return table.copy(pstate) -- give 'em a blank so it don't crash I guess
    end
    return state
end
function player_api.get_state(player, modname)
    local playername = player:get_player_name()
    return player_api.get_state_by_name(playername, modname)
end

function pstate.add(self, state, progress)
    if not states[state] then
        error("Attempted to add unregistered state: "..tostring(state))
    end
    self.list[state] = { name = state, progress = progress }
end
function pstate.add_basic(self, state, label, priority, severity)
    -- Create a simple state on-the-spot without registering first
    if type(priority) == "number" then
        priority = -1 * math.abs(priority)
    end
    if not self.list[state] then
        states[state] = {
            name = state, label = label, priority = priority or -1,
            severity = severity
        }
    end
    self.list[state] = table.copy(states[state]) -- just clone it, lol
end

function pstate.clear(self, state)
    if self.list[state] then
        self.list[state] = nil
    end
end

function pstate.is(self, state)
    if self.list and self.list[state] then return true else return false end
end

local function progress_to_severity(statetable)
    -- Translates a progress number into a severity number
    if not statetable.progress then
        -- better have one or t'other, pardner
        return statetable.severity or states[statetable.name].severity
    end
    local def_thr = { [0] = 20, 40, 60, 80 }
    local stdef = states[statetable.name]
    local threshold = stdef.threshold or def_thr
    local i = 0
    if not threshold[0] then i = 1 end -- technically optional to start at 0
    while i <= #threshold and statetable.progress > threshold[i] do
        i = i + 1
    end
    return i
end

function pstate.get_severity(self, state)
    local stdef = states[state] -- definition
    local stbl = self.list[state] -- current state table
    local sev = 0
    if not stdef or not stbl then return sev end
    if stbl.severity then sev = stbl.severity end
    if stdef.threshold then sev = progress_to_severity(stbl) end
    return sev
end
function pstate.set_severity(self, state, sev)
    local stbl = self.list[state] -- current state table
    stbl.severity = sev
end
function pstate.raise_severity(self, state)
end
function pstate.lower_severity(self, state)
end
function pstate.read_severity(self, state)
    -- Returns a text label version of severity
    local label =
        { S("(mild)"), S("(moderate)"), S("(severe)"), S("(extreme)") }
    local stdef = states[state]
    local stbl = self.list[state]
    if stdef and stdef.severity_txt then label = stdef.severity_txt end
    local sev = stbl.severity or progress_to_severity(stbl)
    if label[sev] then return label[sev] end
    return ""
end

function pstate.add_progress(self, state, adjustment)
    -- +/- adjustment to progress. raises or lowers severity at thresholds

    local stbl = self.list[state]
    if not stbl then -- can't just add it, with no progress or severity
        minetest.log("error",
                     "Tried to alter progress on non-existant state:"..state)
        return
    end
    local sev = progress_to_severity(stbl)
    stbl.progress = stbl.progress + adjustment
    local newsev = progress_to_severity(stbl)
    if sev ~= newsev then
        -- #TODO: run callbacks for state changes
    end
    stbl.severity = newsev
end
function pstate.read_progress(self, state)
    local stbl = self.list[state]
    return stbl.progress
end
function pstate.set_progress(self, state, new_pr)
    local stbl = self.list[state]
    if not stbl then   self:add(state, new_pr)  return  end
    local old_pr = stbl.progress
    if not old_pr then
        stbl.progress = new_pr
        return
    end
    if old_pr == new_pr then return end -- nothing to do, else
    pstate.add_progress(self, state, new_pr - old_pr) -- change, do callbacks
end


local function get_old_effects_list(player, list)
    local label =
        { [0] = "", S("(mild)"), S("(moderate)"),
            S("(severe)"), S("(extreme)") }
    local meta = player:get_meta()
    local effects_list_str = meta:get_string("effects_list")
    local effects_list = minetest.deserialize(effects_list_str) or {}
    for no, effect in ipairs(effects_list) do
        -- effect_list is only modified in health/health_effects.lua and health/init.lua,
        -- so this translator should be fine
        effect[1] = health_S(effect[1])
        effect[2] = label[tonumber(effect[2])] or ""
        table.insert(list, effect)
    end
end

function pstate.read_labels(self)
    -- Reads out labels of all states, sorted so major before minor before info
    -- Used for final display on character tab
    local list_info = {}
    local list_minor = {}
    local list = {}
    local pri_order = { list_info, list_minor, list }
    get_old_effects_list(self.player, list) -- old effects, all counted as major
    for name, statetbl in pairs(self.list) do
        local stdef = states[name]
        local label = statetbl.label or ( stdef and stdef.label )
        if label and label ~= "" then
            if label == "-" then label = "" end
            local sev = statetbl.severity
                or progress_to_severity(statetbl)
                or 0
            local pri = math.abs(statetbl.priority
                                 or states[name].priority)
                or 1
            local sevname = self:read_severity(name, sev)
            if sevname ~= "" then
                --^^ in case of "-" sev-only label and there's no severity name
                if label == "" then
                    -- if no label, only displays the severity name
                    table.insert(pri_order[pri], { sevname })
                else
                    table.insert(pri_order[pri], { label.." ", sevname })
                end
            end
        end
    end
    for i = 1, #list_minor do
        table.insert(list, list_minor[i])
    end
    for i = 1, #list_info do
        table.insert(list, list_info[i])
    end
    return list
end

minetest.register_on_newplayer(function(player)
        local pname = player:get_player_name()
        blank_states(player, pname)
end)

minetest.register_on_joinplayer(function(player, lastlogin)
        local pname = player:get_player_name()
        load_states(player, pname)
end)

minetest.register_on_dieplayer(function(player)
        local pname = player:get_player_name()
        blank_states(player, pname)
end)

--[[
    minetest.register_chatcommand("states", {
    description = "Show your player states",
    func = function(name, param)
    print(dump(player_api.get_state_by_name(name).list))
    end
    })
]]--
