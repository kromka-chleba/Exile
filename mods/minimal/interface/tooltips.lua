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

                    -- the following gives error if some of the tool_tips had
                    -- "\n" IN the S(...) translation thing
                    -- like S("blabla\n thing")
                    -- while S("blabla") .. "\n" .. "S(thing)" will be fine
                    -- I changed it in the hammer that was raising it but...
                    -- in case of some other are left/may happen in the future,
                    -- I also stopped using colorize here.
                    ttip = color_esc("#ccccff")
                            .. ttip
                            .. color_esc("#ffffff")
                    -- [[
                    --local esc = core.formspec_escape
                    --ttip = esc(core.colorize("#ccccff", ttip))
                    --]]

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
