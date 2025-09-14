-- localisation
local crafting = crafting
local S = core.get_translator("crafting")
local tofstring = function(t) return table.concat(t,"") end

--[[ Cache fields----------------------------------------------------------
1) Tools :
------------
`tool_list` = list of tools I can use, currently {hand,station used}
`sToolID` = selected tool index in list -- set to 1 by default
`sTool`  = selected tool name
``FS_tool_panel` = nil -- tools formspec

2) craft types (subtabs)
-------------------------
`sTab`   = 1 : index of selected_craft_tab
`cTabs` = nil : "hand", "hand_tool", etc; all output tool type sections
`sLevel` = selected craft_types'level
`FS_ctabs` = nil -- craft tabs formspec
]]

-- registering all craft type (tabs) and level available per tool
-- #TODO could be check once at login I guess
local tools_craft_tabs = {}

-- return table of craft subtabs for tool in parameter
-- set by def.exile_crafting.craft_type of registered tool/item/node
local function get_craft_types(tool)
    if not tool then
        return get_craft_types(crafting.default_tool)
    -- use the data we already have
    elseif tools_craft_tabs[tool] then
        return tools_craft_tabs[tool]
    end
    -- generate the list if not enough data
    local def = minetest.registered_nodes[tool]
        or minetest.registered_tools[tool]
        or minetest.registered_items[tool]
    if def and def.exile_crafting then
        local tabs = def.exile_crafting.craft_types
        if not tabs then
            error('no tabs defined for '.. tool)
        end
        if type(tabs) ~= 'table' then
            tabs = { tabs }
        end
        tools_craft_tabs[tool] = tabs
        return tabs
    else
        print('ERROR: Missing exile_crafting craft_types definition for '..tool)
    end
end

local tools_level = {}
-- return level for that tool (#TODO I think this is unused, not sure yet)
-- set by def.exile_crafting.craft_level of registered tool/item/node
function crafting.get_tool_level(tool)
    if not tool then
        return crafting.get_tool_level(crafting.default_tool)
    -- use the data we already have in local
    elseif tools_level[tool] then
        return tools_level[tool]
    else
        -- go get it in registered table else
        local def = minetest.registered_nodes[tool]
            or minetest.registered_tools[tool]
            or minetest.registered_items[tool]
        if def and def.exile_crafting then
            tools_level[tool] = def.exile_crafting.craft_level
            return tools_level[tool]
        else
            print('ERROR: Missing exile_crafting level definition for '..tool)
        end
    end
end

-- station's tool lists -------------------------------------------------------

-- Load craft type : buttons on the top left "tool used"
--[[#TODO right now, only one tool can be used at the same time (placed tool)
but we could imagine using tool in inventory like knifes too
In that case, this could be modified to have "craft_item" being a list]]
function crafting.generate_tools_list(station_name)
    -- #TODO this could be improved to check if station is a valid tool/
    -- to make custom possbile tools per station
    if not station_name or station_name == crafting.default_tool then
        return {crafting.default_tool}
    else
        return {crafting.default_tool, station_name}
    end
end

local function val_to_ID(val, table)
    for i, v in pairs(table) do
        if v == val then
            return i
        end
    end
end

-- FORMSPEC generations --------------------------------------------------------

-- Draw the tool type part
--[[Shouldn't need to rebuild this more then once per player per restart
    or when player adds to their craft_types
    See adding tools/benches to input_items list]]
-- cache parameter is optional
local function get_tool_panel(cache)
    local selected = cache.sTool or crafting.default_tool -- default to hand crafting
    local tool_list = cache.tool_list or crafting.generate_tools_list()
    local FS_tool_tabs = {
        'label[0,0;'..S("Tool used")..']',
        'container[0,0.3]',
        'style_type[item_image_button;border=false;bgimg_middle=]'
    }

    local x = 0
    local y = 0
    local coords
    local bg_image
    for i,tool in ipairs(tool_list) do
        coords = tostring(x * 1.0) ..','.. tostring(y * 1.0)
        if tool == selected then
            bg_image = 'selected.png'
        else
            bg_image = 'not_selected.png'
        end

        FS_tool_tabs[#FS_tool_tabs + 1] =
            "image[" .. coords .. ";0.9,0.9;" .. bg_image .. "]"

        if tool~="" then
            -- Dipslay item image
            FS_tool_tabs[#FS_tool_tabs + 1] =
               'item_image_button[' .. coords .. ';0.9,0.9;'
               .. tool ..';b_sTool_' .. i .. ';]'
            FS_tool_tabs[#FS_tool_tabs + 1] =
                'tooltip[b_sTool_' .. i .. ';'
                .. ItemStack(tool):get_short_description() .. ']'
        end
        x = x + 1
        if x > 1 then
            x = 0
            y = y + 1
        end
    end

    FS_tool_tabs[#FS_tool_tabs + 1] ='container_end[]'
    return tofstring(FS_tool_tabs)
end

-- generate  tool panel formspec
crafting.register_cache_function("get_tool_panel", get_tool_panel)

-- Craft tabs FS generation --
local function get_craft_tabs(cache)
    local cTabs = cache.cTabs
    if not cTabs then
        core.log("no craft tabs info to generate formspec")
        return ""
    end

    local pan_t = {
        --style 1 : no border
        "style_type[item_image_button;border=false;bgimg_middle=4]",
        "style_type[image_button;border=false;bgimg_middle=4]"

        --[[ style 2 : with border
        "style_type[item_image_button;border=true;bgimg_middle=4]",
        --if this tab is selected, change style
        "style[sCraftTab_"..sTab..";bgcolor=#FFFFFF]"]]
    }

    local coords
    for i=1, #cTabs do -- go over recipe tabs: hand, tools, weaving, etc
        coords = tostring((i - 1) * 0.85) ..',0'
        ---------------------------------------------------------------
        --set focus on selected tab
        if i == cache.sTab then
            pan_t[#pan_t + 1] =
            'set_focus[sCraftTab_' .. i .. ';true]'
            -- style 1 : no border
            pan_t[#pan_t + 1] =
            "image[" .. coords .. ";0.8,0.8;selected.png]"
        --else
            -- style 1 : no border
            --[[uncomment this to activate background of tabs
            pan_t[#pan_t + 1] =
            "image[" .. coords .. ";0.8,0.8;not_selected.png]"
            ]]
        end

        local item_name = crafting.get_type(cTabs[i]).icon_item_name
        or 'crafting:placeholder'

        -- checking if given field is an image or not.
        local button_type = 'item_image_button['
        if item_name == string.gsub(item_name, ":", "") then -- not an item
            button_type = 'image_button['
        end

        pan_t[#pan_t + 1] = button_type .. coords .. ';0.8,0.8;'.. item_name .. ';sCraftTab_'..i..';]'

        pan_t[#pan_t + 1] = 'tooltip[sCraftTab_'.. i ..';'
        .. minetest.formspec_escape(crafting.get_type(cTabs[i]).label)
        ..';#000000;#ffffff]'
    end

    return tofstring(pan_t)
end

-- generate craft tabs formspec
crafting.register_cache_function("get_craft_tabs",get_craft_tabs)


-- FORMSPEC actions ------------------------------------------------------------


-- Functions -------------------------------------------------------------------

-- set craft tabs in cache
crafting.register_cache_function("set_craft_tabs",
    function(self, sTab, cTabs)
    self.sTab = sTab or self.sTab or 1
    self.cTabs = cTabs or self.cTabs or get_craft_types(self.sTool)
    -- erases craft tabs formspec
    self.FS_ctabs = nil
    -- reset qty to 1
    self.qty = 1 -- single by default on opening
    -- reset recipes but keep current cache's item_hashes
    self:reset_recipes(true)
    -- set scrollbar to top
    self.sScroll = 0 -- reset scrollbar to top
end)

-- set tool in cache, `tool` is optional
-- changes to default_tool if `tool` == `nil`
crafting.register_cache_function("set_tool", function(self, tool)
    -- if no parameter tool is given, put default tool
    tool = tool or crafting.default_tool
    -- reset the tool panel in any case, because we may arrive here by changing station, evenkeeping the same tool
    self.FS_tool_panel = nil
    -- don't reset tabs if tool didn't change
    if self.sTool ~= tool then
        -- initialize cache
        self.sTool = tool
        self.sToolID =  val_to_ID(tool, self.tool_list)
        self.sLevel = crafting.get_tool_level(tool)
        -- reset craft type tabs
        self:set_craft_tabs(1, get_craft_types(tool))
    end
end)
