----------------------------------------------------------
--UCSIGNS mod support

-- Internationalisaton
local S = tech.S

local ucsigns_available = minetest.get_modpath("ucsigns")
if not ucsigns_available then return end

print("UCSIGNS AVAILABLE: ",ucsigns_available)
screwdriver = lever
-- colours the inventory image of the signs
local signcolors = {
    tangkal = "#8a7362",
    sasaran = "#977961",
    maraka = "#9e8364",
    kagum = "#8a7957",
    amma = "#f8dba6",
    daoja = "#a7875b",
    jalowiec = "#d9a07b",
    panasee = "#ae8d62",
    tulatula = "#77674a",
}
-- sign crafting type
crafting.register_type("ucsign",
  S("Signs"),
  "ucsigns:wall_sign_exile",
  {name = "nodes_nature_dig_choppy", pitch={0.9,1.3}}
)
-- basic exile brand signdef
local signdef = {
    groups = {oddly_breakable_by_hand = 1, ucsign = 1, choppy = 2},
    sounds = nodes_nature.node_sound_wood_defaults(),
    -- custom on_rightclick function for sign text editing and colouring
    on_rightclick = function(pos, node, clicker, itemstack, pointed_thing)
        local meta = core.get_meta(pos)
        -- can't colour or change text (protected)
        if core.is_protected(pos, clicker, meta) then return end
        local itemdef = itemstack:get_definition()
        -- we're gon colour this sign the way we want
        if itemdef.inventory_image == "blank_dye.png" and itemdef.color then
            -- black defaults to empty string
            local color = itemdef.color ~= "#202020" and itemdef.color or ""
            if meta:get_string("color") == color then return end
            meta:set_string("color", color)
            ucsigns.update_sign(pos)
            if not minimal.player_in_creative(clicker) then
                itemstack:take_item()
            end
        -- rewrite history!
        else
            ucsigns.show_formspec(clicker, pos)
        end
    end,
    -- save text and text colouring
    preserve_metadata = function(pos, oldnode, oldmeta, drops) -- preserve_metadata
        local stack = drops[1]
        -- not going to using much of meta, save what we want
        oldmeta = {color=oldmeta.color, text=oldmeta.text}
        oldmeta.color = oldmeta.color ~= "" and oldmeta.color or nil -- don't save if no colour
        if not next(oldmeta) then return end -- nothing to save
        -- if we keep color as is as variable, it colours the itemstack which we don't want
        oldmeta.textcolor = oldmeta.color
        oldmeta.color = nil
        -- save to meta
        local imeta = stack:get_meta()
        imeta:from_table({fields = oldmeta})
    end,
    after_place_node = function(pos, placer, itemstack, pointed_thing)
        local oldmeta = itemstack:get_meta()
        oldmeta = oldmeta:to_table()
        if not oldmeta then return end -- nothing we can do here
        -- convert to fields
        oldmeta = oldmeta.fields
        if not next(oldmeta) then return end -- nothing to do here
        -- get text color and remove old textcolor value
        oldmeta.color = oldmeta.textcolor
        oldmeta.textcolor = nil
        -- now set meta
        local meta = core.get_meta(pos)
        meta:from_table({fields = oldmeta})
        ucsigns.update_sign(pos)
    end,
    -- prevent rotation with levers until either it's fixed upstream or we fixed it
    on_rotate = function(pos, node, user, mode, new_param2)
        return
    end
}
-- rotation fixed upstream, permit rotation
if ucsigns.merge_itemdef then
    signdef.on_rotate = nil
end
-- make a unique sign for every tree type
for nname, ndef in pairs(core.registered_nodes) do
    if ndef.groups and ndef.groups.log and ndef.tiles and
      -- if tree variant exists
      core.registered_nodes[ndef.name:gsub("_log","_tree")] then
        -- let's dew it!
        -- remove mod name and _log
        local name = ndef.name:sub(#ndef.mod_origin+2,-5)
        -- sign has issues with 16x16, let's increase it twofold
        local tiles = table.copy(ndef.tiles)
        for ind,tile in ipairs(tiles) do
            -- a bunch of weird calculations I did late at night that don't work upscaled - TPH
            local newtile = "[combine:32x32:"
            for i=1, 4 do
                local x,y = (i > 2 and 16 or 0), (i%2*16)
                newtile = newtile..x..","..y.."="..tile
                newtile = i ~= 4 and newtile..":" or newtile
            end
            tiles[ind] = newtile
        end
        -- permit custom "average_color" (what the node color theoretically should be on a minimap)
        local signcolor = ndef.average_color or signcolors[name] or nil
        name = "exile_"..name
        ucsigns.register_sign(name, signcolor, minimal.merge_tables(signdef, {
            -- #TODO this should be changed: it may not allow proper translation
            -- TR: @1 is the description of a woody node
            description = S("@1 Sign", ndef.description),
            tiles = tiles
        }))
        -- ucsigns doesn't properly check and duplicate groups and causes issues
        -- so we'll have to manually add a flag to not be in the creative inventory to declutter
        local standdef = core.registered_nodes["ucsigns:standing_sign_"..name]
        local standgroups = table.copy(signdef.groups)
        standgroups.not_in_creative_inventory = 1
        core.override_item(standdef.name, {
            groups = standgroups
        })
        -- register recipe
        crafting.register_recipe({
                type = "ucsign",
                output = "ucsigns:wall_sign_"..name,--"ucsigns:wall_sign_exile 1",
                items = {ndef.name},
                level = 1,
                always_known = true,
        })
    -- add ucsigns crafting station to axes and adzes
    elseif ndef.exile_crafting and ndef.exile_crafting.craft_types and ndef.name:match("placed") then
        local craftypes = ndef.exile_crafting.craft_types
        for _,ctype in ipairs(craftypes) do
            if ctype == "axe" then
                craftypes[#craftypes + 1] = "ucsign"
                break
            end
        end
    end
end
-- oiled sign (previous default)
ucsigns.register_sign("exile", nil, minimal.merge_tables(signdef, {
    description = S("Oiled Sign"),
    tiles = { "tech_oiled_wood.png" }
}))
-- ditto to above disclaimer for why this needs to be done
local standdef = core.registered_nodes["ucsigns:standing_sign_exile"]
local standgroups = table.copy(signdef.groups)
standgroups.not_in_creative_inventory = 1
core.override_item(standdef.name, {
    groups = standgroups
})
-- oiled recipe
crafting.register_recipe({
    type = "ucsign",
    output = "ucsigns:wall_sign_exile 1",
    items = {"group:log 1", "tech:vegetable_oil"},
    level = 1,
    always_known = true,
})

-- iron sign
-- can't be dug by hand, requires pickaxe or chisel

-- iron sign tiles
-- sign has issues with 16x16, let's increase its size by twofold (copy of above for tree-based signs)
local iron_tiles = {"tech_iron.png"}
for ind,tile in ipairs(iron_tiles) do
    -- a bunch of weird calculations I did late at night that don't work upscaled - TPH
    local newtile = "[combine:32x32:"
    for i=1, 4 do
        local x,y = (i > 2 and 16 or 0), (i%2*16)
        newtile = newtile..x..","..y.."="..tile
        newtile = i ~= 4 and newtile..":" or newtile
    end
    iron_tiles[ind] = newtile
end
ucsigns.register_sign("exile_iron", "#686868", minimal.merge_tables(signdef, {
    description = S("Iron Sign"),
    tiles = iron_tiles,
    groups = {choppy=0, oddly_breakable_by_hand=0, handy=0, axey=0, ucsign=1, not_in_creative_inventory=1, cracky=3},
    sounds = tech.node_sound_metal_hollow_defaults()
}))
-- ditto ditto to above disclaimer for why this needs to be done
local walldef = core.registered_nodes["ucsigns:standing_sign_exile_iron"]
local wallgroups = table.copy(walldef.groups)
wallgroups.not_in_creative_inventory = nil
wallgroups.deco_block = 1
core.override_item(walldef.name, {
    groups = wallgroups
})
-- iron sign recipe
crafting.register_recipe({
    type = "anvil",
    output = "ucsigns:wall_sign_exile_iron 1",
    items = {"tech:iron_ingot"},
    level = 1,
    always_known = true,
})
