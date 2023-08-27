minimal = minimal

local themes = {
   ["antiglass"] =
      "background9[0,0;,;9slice-hollow.png;true;10]"..
      "style_type[button;bgimg=9slice.png;bgimg_middle=10]"..
      "listcolors[#00000069;#5A5A5A;#141318;#30434C;#FFF]",
   ["antiblue"] =
      "background9[0,0;,;9slice-deep.png;true;10]"..
      "style_type[button;bgimg=9slice.png;bgimg_middle=10]"..
      "listcolors[#00000069;#5A5A5A;#141318;#30434C;#FFF]",
}

themes.default = themes[minetest.settings:get("exile_default_gui_theme")] or
   themes.antiglass

function minimal.apply_gui_theme(player, meta)
   if not meta then
      meta = player:get_meta()
   end
   local selection = meta:get("gui_theme")
   if not themes[selection] then
      selection = "default"
   end
   player:set_formspec_prepend(themes[selection])
end

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
   minimal.apply_gui_theme(player, meta)
   return true
end

minetest.register_chatcommand("set_theme", {
    params = "<themename> | list | clear",
    description = "Sets your gui theme",
    func = function(name, param)
       if param == "" then
	  return true, "Please enter list to list available themes, \n"..
	     " clear to remove your preferences, or a theme name."
       end
       if param == "list" then
	  local listy = ""
	  for nm, _ in pairs(themes) do
	     if nm ~= "default" then
		listy = listy..nm.."\n"
	     end
	  end
	  return true, listy
       end
       local worked = minimal.set_gui_theme(minetest.get_player_by_name(name),
					    nil,
					    param)
       if not worked then
	  return false, "invalid theme name"
       end
       return worked
    end
})
