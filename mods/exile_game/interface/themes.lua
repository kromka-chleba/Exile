-- translation
local S = EXILE.S

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
    ["Legacy Grey 2"] =
        "bgcolor[#080808BB;false]"..
        "background9[5,5;1,1;gui_formbg.png;true;10]"..
        "listcolors[#00000069;#5A5A5A;#141318;#30434C;#FFF]",
    ["Hi Contrast"] =
        "bgcolor[#00000000;false]"..
        "background9[5,5;1,1;gui_formbg.png;true;10]"..
        "background9[5,5;1,1;gui_formbg.png\\^\\[colorize:\\#131313;true;10]"..
        "listcolors[#000000FF;#AAAAAA;#DDDDDD;#12181A;#FFF]",
}

themes.default = themes[minetest.settings:get("exile_default_gui_theme")] or
    themes.Antiglass

-- To allow translation
--[[#TODO description field is unused yet,
    intention was to use it (maybe) to display a description under the dropdown in formspec,
    for example to explain what "default" theme is]]
local themes_by_id = {
    {name = "default", title = S('Default'), description = ""},
    {name = "Antiglass" , title = S('Antiglass'), description = ""},
    {name = "Antiblue", title = S('Antiblue'), description = ""},
    {name = "Legacy Grey", title = S('Legacy Grey'), description = ""},
    {name = "Legacy Grey 2", title = S('New Grey'), description = ""},
    {name = "Hi Contrast", title = S('Coal Black'), description = ""},
}

--return list of theme's names (translated version to display)
function EXILE.get_gui_theme_titles()
    local l = {}
    for id, theme in ipairs(themes_by_id) do
        l[id] = theme.title
    end
    return l
end

--return list of themes
function EXILE.get_gui_theme_list()
    local l = {}
    for id, theme in ipairs(themes_by_id) do
        l[id] = theme.name
    end
    return l
end

-- apply theme
function EXILE.apply_gui_theme(player, meta, name)
    if not name and not meta then
        meta = player:get_meta()
    end
    if not name then
        name = meta:get("gui_theme")
    end
    if not themes[name] then
        name = "default"
    end
    print("Setting theme to ",name)
    print(dump(themes[name]))
    player:set_formspec_prepend(themes[name])
end

-- save theme in player's meta, then applies it
function EXILE.set_gui_theme(player, meta, themename)
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
    EXILE.apply_gui_theme(player, meta, themename)
    return true
end
