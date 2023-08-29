minimal = minimal

local themes = {
   ["Antiglass"] =
      "bgcolor[#080808BB;true]"..
      "background9[0,0;,;9slice-hollow.png;true;10]"..
      "style_type[button;bgimg=9slice.png;bgimg_middle=10]"..
      "listcolors[#00000069;#5A5A5A;#141318;#30434C;#FFF]",
   ["Antiblue"] =
      "bgcolor[#000008BB;true]"..
      "background9[0,0;,;9slice-deep.png;true;10]"..
      "style_type[button;bgimg=9slice.png;bgimg_middle=10]"..
      "listcolors[#00000069;#5A5A5A;#141318;#30434C;#FFF]",
   ["Legacy Grey"] =
      "bgcolor[#080808BB;true]"..
      "background9[5,5;1,1;gui_formbg.png;true;10]"..
      "listcolors[#00000069;#5A5A5A;#141318;#30434C;#FFF]",
}

themes.default = themes[minetest.settings:get("exile_default_gui_theme")] or
   themes.Antiglass

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

function minimal.get_gui_theme_list(separator)
   -- Returns either a table, or a string if separator is specified
   local listy = ""
   local tabley = {}
   local sep = ""
   for nm, _ in pairs(themes) do
      if separator == nil or type(separator) ~= "string" then
	 table.insert(tabley, nm)
	 listy = nil
      else
	 listy = listy..sep..nm
	 sep = separator -- Don't add the separator before the first one
      end
   end
   return listy or tabley
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
