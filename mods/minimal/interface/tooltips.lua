minetest.register_on_mods_loaded(function()
      for name, def in pairs(minetest.registered_items) do
	 if def._orig_desc then
	    minetest.log("error","Tried to set tooltips on "..name.." twice!")
	 else
	    local orig_desc = def.description
	    local newdesc = def.description
	    local ttip = ""
	    local digtip = def._dig_tip
	    local usetip = def._use_tip
	    local placetip = def._place_tip
	    if digtip or usetip or placetip then
	       ttip = ttip.."\n"
	       if digtip then
		  ttip = ttip.."\n  ^ : "..digtip
	       end
	       if usetip then
		  ttip = ttip.."\n  ◊ : "..usetip
	       end
	       if placetip then
		  ttip = ttip.."\n  v : "..placetip
	       end
	       newdesc = newdesc..minetest.colorize("#ccccff", ttip)
	       minetest.override_item(name, { description = newdesc,
					      _orig_desc = orig_desc })
	    end
	 end
      end
end)
