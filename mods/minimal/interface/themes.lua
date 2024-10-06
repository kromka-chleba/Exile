minimal = minimal -- Only used to extend namespace

-- translation
local S = minimal.S

local themes = {
    ["Antiglass"] =
        "bgcolor[#080808BB;false]"..
        "background9[0,0;,;9slice-hollow.png;true;10]"..
        "style_type[button;bgimg=9slice.png;bgimg_middle=6]"..
        "listcolors[#00000069;#5A5A5A;#141318;#30434C;#FFF]",
    ["Antiblue"] =
        "bgcolor[#000008BB;true]"..
        "background9[0,0;,;9slice-deep.png;true;10]"..
        "style_type[button;bgimg=9slice.png;bgimg_middle=6]"..
        "listcolors[#00000069;#5A5A5A;#141318;#30434C;#FFF]",
    ["Legacy Grey"] =
        "bgcolor[#080808BB;true]"..
        "background9[5,5;1,1;gui_formbg.png;true;10]"..
        "listcolors[#00000069;#5A5A5A;#141318;#30434C;#FFF]",
}

themes.default = themes[minetest.settings:get("exile_default_gui_theme")] or
    themes.Antiglass

-- To allow translation
--[[#TODO descrption field is unused yet,
    intention was to use it (maybe) to display a description under the dropdown in formspec, for example to explain what "default" theme is]]
local themes_by_id = {
    {name = "default", title = S('Default'), description = ""},
    {name = "Antiglass" , title = S('Antiglass'), description = ""},
    {name = "Antiblue", title = S('Antiblue'), description = ""},
    {name = "Legacy Grey", title = S('Legacy Grey'), description = ""}
}

--return list of theme's names (translated version to display)
function minimal.get_gui_theme_titles()
    l = {}
    for id, theme in ipairs(themes_by_id) do
        l[id] = theme.title
    end
    return l
end

--return list of themes
function minimal.get_gui_theme_list()
    l = {}
    for id, theme in ipairs(themes_by_id) do
        l[id] = theme.name
    end
    return l
end

-- apply theme
function minimal.apply_gui_theme(player, meta, name)
    if not name and not meta then
        meta = player:get_meta()
    end
    if not name then
        name = meta:get("gui_theme")
    end
    if not themes[name] then
        name = "default"
    end
    player:set_formspec_prepend(themes[name])
end

-- save theme in player's meta, then applies it
function minimal.set_gui_theme(player, meta, themename)
    if not meta then
        meta = player:get_meta()
    end
    if themename == "clear" then
        themename = ""
    end
    if type(themename) ~= "string" or ( not themes[themename] and
                                        themename ~= "" ) then
        return false
    end
    meta:set_string("gui_theme", themename)
    minimal.apply_gui_theme(player, meta, themename)
    return true
end
