-- auto generate _tool_tips for all registered items
--  defining  _dig_tip, _use_tip, or _place_tip
-- Stored in def._tool_tips

-- crafting/api.lua sets meta description using it which appears with mouseover.
minetest.register_on_mods_loaded(function()
        local color_esc = core.get_color_escape_sequence
        for name, def in pairs(minetest.registered_items) do
            --[[ takes old descriptions to add tool tips to them
            if not already done
            that tool_tip adds use/place/dig instructions ]]
            if def._orig_desc then
                minetest.log("error","Tried to set tooltips on "..name..
                             " twice!")
            else
                local ttip = ""
                local digtip = def._dig_tip
                local usetip = def._use_tip
                local placetip = def._place_tip
                if digtip or usetip or placetip then
                    -- add dedicated color
                    -- WARNING: translation + colorize do weird things together
                    -- that is why I changed the
                    -- [[
                    --local esc = core.formspec_escape
                    --ttip = esc(core.colorize("#ccccff", ttip))
                    --]]

                    ttip = ttip.."\n" .. color_esc("#ccccff")
                    if digtip then
                        ttip = ttip.."\n  ^ : "..digtip
                    end
                    if usetip then
                        ttip = ttip.."\n  ◊ : "..usetip
                    end
                    if placetip then
                        ttip = ttip.."\n  v : "..placetip
                    end

                    -- back to white after the tooltip
                    ttip =  ttip .. color_esc("#ffffff")

                    local orig_desc = def.description

                    minetest.override_item(
                        name, {
                            _tool_tips = ttip,
                            description = orig_desc..ttip,
                            _orig_desc = orig_desc
                    })
                end
            end
        end
end)
