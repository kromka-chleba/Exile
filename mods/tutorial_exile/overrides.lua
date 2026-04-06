local S = minetest.get_translator("tutorial_exile")

-- Dyer's Table
--
-- Don't want players finding the dyes on your server while sitting
--  comfortably in the crafting tutorial area

-- We can remove the items from their inventory,
--  but we can't remove knowledge from a player's head

local tablenode = "ncrafting:dye_table"
local table_formspec_tutorial = "formspec_version[5]" ..
    "size[11,5.5]" ..
    "label[3.55,0.5;"..S("Disabled in the tutorial").."]"

local oldafter = minetest.registered_nodes[tablenode].after_place_node
local oldonrec = minetest.registered_nodes[tablenode].on_receive_fields

minetest.override_item(
    tablenode,
    {
        after_place_node = function(pos, placer, itemstack, pointed_thing, nmeta, _imeta)
            if pos.y < 9000 then
                oldafter(pos, placer, itemstack, pointed_thing)
                return
            end
            nmeta = nmeta or core.get_meta(pos)
            nmeta:set_string("formspec", table_formspec_tutorial)
            local inv = nmeta:get_inventory()
            inv:set_size("craft", 1)
            inv:set_size("craftresult", 1)
        end,
        on_receive_fields = function(pos, formname, fields, sender)
            if pos.y < 9000 then
                oldonrec(pos, formname, fields, sender)
                return
            end
        end
})
