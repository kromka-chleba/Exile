-- auto generate _tool_tips for all registered items
--  defining  _dig_tip, _use_tip, or _place_tip
-- Stored in def._tool_tips

-- crafting/api.lua sets meta description using it which appears with mouseover.
minetest.register_on_mods_loaded(function()
        for name, def in pairs(minetest.registered_items) do
            if def._orig_desc then
                minetest.log("error","Tried to set tooltips on "..name..
                             " twice!")
            else
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
                    local orig_desc = def.description
                    local new_desc = orig_desc..ttip
                    minetest.override_item(
                        name, {
                            _tool_tips=minetest.colorize("#ccccff",
                                                         ttip),
                            description = new_desc,
                            _orig_desc = orig_desc
                    })
                end
            end
        end

end)

