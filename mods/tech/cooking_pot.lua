----------------------------------------------------------
--COOKING POT

local S = tech.S

minimal = minimal
liquid_store = liquid_store

local random = math.random

--[[
consider these node-wise:

temp
portions

]]--

---------------------
local pot_box = {
    {-0.375, -0.1875, -0.375, 0.375, -0.0625, 0.375}, -- NodeBox1
    {-0.3125, -0.3125, -0.3125, 0.3125, -0.1875, 0.3125}, -- NodeBox2
    {-0.25, -0.4375, -0.25, 0.25, -0.3125, 0.25}, -- NodeBox3
    {-0.3125, -0.0625, -0.3125, 0.3125, 0, 0.3125}, -- NodeBox4
    {-0.25, 0, -0.25, 0.25, 0.0625, 0.25}, -- NodeBox5
    {-0.125, 0.0625, -0.0625, -0.0625, 0.1875, 0.0625}, -- NodeBox6
    {0.0625, 0.0625, -0.0625, 0.125, 0.1875, 0.0625}, -- NodeBox7
    {-0.0625, 0.125, -0.0625, 0.0625, 0.1875, 0.0625}, -- NodeBox8
    {0.25, -0.4375, 0.25, 0.375, -0.3125, 0.375}, -- NodeBox9
    {0.25, -0.5, 0.25, 0.4375, -0.4375, 0.4375}, -- NodeBox10
    {0.25, -0.5, -0.4375, 0.4375, -0.4375, -0.25}, -- NodeBox11
    {-0.4375, -0.5, -0.4375, -0.25, -0.4375, -0.25}, -- NodeBox12
    {-0.4375, -0.5, 0.25, -0.25, -0.4375, 0.4375}, -- NodeBox13
    {0.25, -0.4375, -0.375, 0.375, -0.3125, -0.25}, -- NodeBox14
    {-0.375, -0.4375, -0.375, -0.25, -0.3125, -0.25}, -- NodeBox15
    {-0.375, -0.4375, 0.25, -0.25, -0.3125, 0.375}, -- NodeBox16
    {-0.4375, -0.0625, -0.0625, -0.3125, 0.0625, 0.0625}, -- NodeBox23
    {0.3125, -0.0625, -0.0625, 0.4375, 0.0625, 0.0625}, -- NodeBox24
}

local bowl_box = {
    {-2/16,-0.5,-2/16, 2/16,-7/16,2/16}, -- bottom
    -- 2nd
    {-3/16,-7/16,3/16, 3/16,-6/16,2/16}, -- back (+Z)
    {-3/16,-7/16,-3/16, 3/16,-6/16,-2/16}, -- front (-Z)
    {3/16,-7/16,-2/16, 2/16,-6/16,2/16}, -- right (+X)
    {-3/16,-7/16,-2/16, -2/16,-6/16,2/16}, -- left (-X)
    -- 3rd
    {-4/16,-6/16,4/16, 4/16,-5/16,3/16}, -- back (+Z)
    {-4/16,-6/16,-4/16, 4/16,-5/16,-3/16}, -- front (-Z)
    {4/16,-6/16,-3/16, 3/16,-5/16,3/16}, -- right (+X)
    {-4/16,-6/16,-3/16, -3/16,-5/16,3/16}, -- left (-X)
}

-- create bowl_fill_nodebox by adding a thin top layer to emulate soup
local bowl_fill_box = table.copy(bowl_box)
bowl_fill_box[#bowl_box + 1] = {-3/16,-6/16,-3/16, 3/16,-5.2/16,3/16}

-- miscellaneous soup functions

-- get what soup/stew it should become judging by definition and the kind specified
-- mod_origin for differring mods
local function soup_get_become(def, kind, mod_origin)
    kind = kind:lower()
    -- what type the filled soup/stew or filled bowl is, permit custom
    local result = kind == "stew" and def.stew_to or kind == "soup" and def.soup_to or
        "_"..kind
    -- gets soup/stew_to variable, adds self name if no colon (indicative of proper name) found
    result = (not result:match(":")) and def.name..result or result -- allow for simple like "_soup"
    if type(mod_origin) == "string" and def.mod_origin ~= mod_origin then
        -- remove old mod_name from beginning of name (by string.sub'ing own mod_origin length + 1)
        -- add differing mod_origin
        -- could use :gsub() but what if someone has the mod_origin somewhere else in the name? and why readd ":"?
        result = mod_origin..result:sub((#def.mod_origin)+1)
    end
    if not minetest.registered_nodes[result] then return end -- not a valid node if specified
    return result
end

-- basically we want to get the become variant of empty
-- and get the empty variant of become
-- so we essentially reverse what was given to us
-- accepts itemstack, pos, or nodename string for either
local function get_empty_become(empty, become)
    -- get definition of empty
    local edef = type(empty) == "userdata" and empty.get_definition and empty:get_definition() or
        vector.check(empty) and minimal.get_nodedef(empty) or core.registered_nodes[empty]
    if not edef then return end
    -- get definition of become
    local bdef = type(become) == "userdata" and become.get_definition and become:get_definition() or
        vector.check(become) and minimal.get_nodedef(become) or core.registered_nodes[become]
    if not bdef then return end
    -- get "soup kind" from either bdef's soup_kind, groups, or grabbing the last 4 characters of its name
    -- which should either be "soup" or "stew"
    local kind = type(bdef.soup_kind) == "string" and bdef.soup_kind or
        bdef.groups and (bdef.groups.soup and "soup" or bdef.groups.stew and "stew") or bdef.name:sub(-4)
    -- get become variant of empty
    become = soup_get_become(edef, kind, bdef.mod_origin)
    -- get empty variant of become
    empty = bdef.soup_empty or bdef.name:sub(1,-6)
    -- return on success, will be string
    if become and core.registered_nodes[empty] then
        -- empty will be the empty variant of become
        -- become will be the become variant of empty
        return empty, become
    end
end

-- handles soup/stew/custom bowl with empty bowl interactions
-- itemstack is what will be depleted/replaced
-- adding is what we're adding to the player's inventory
-- user is the player/entity performing this action
-- NOT REQUIRED PARAMETER: inv is the inventory of "user" - will be grabbed from "user" if not provided
local function soup_handle_inventory(itemstack, adding, user, inv)
    -- get inventory if not provided (permits use by custom entities)
    inv = inv or (type(user) == "table" or type(user) == "userdata")
        and user.get_inventory and user:get_inventory()
    if not inv then return end
    -- inventory functionality
    local plr_creative = minimal.player_in_creative(user)
    local deplete_stack = false -- depleting instead of replacing
    -- original bowl will not be replaced (more than 1 or player in creative)
    if itemstack:get_count() > 1 or plr_creative then
        if inv:room_for_item("main", adding) then
            deplete_stack = not plr_creative and true
            inv:add_item("main", adding)
        -- can't add, warn player
        elseif core.is_player(user) then
            deplete_stack = not plr_creative and true -- deplete anyways but one day fix this
            -- also drop at feet
            core.add_item(user:get_pos(), adding)
            minimal.warn_inv_full(user)
        end
    -- bowl will be depleted, simply replace instead
    else
        itemstack = adding
    end
    -- take away 1 bowl
    if deplete_stack then
        itemstack:take_item()
    end
    return itemstack
end

-- soup node functions

-- soup transfer - for transferring itemstack soups/stews/filled bowls to empty bowl nodes
local function soup_transfer(pos, user, itemstack, p_inv, nodemeta, imeta)
    -- get itemstack definition for soup_no_meta_transfer check
    local itemdef = itemstack:get_definition()
    -- get empty of itemstack, become of empty bowl at pos
    local empty, become = get_empty_become(pos, itemdef.name)
    -- could not transfer (no empty or no become)
    if not (empty and become) then return end
    -- we can transfer this soup/stew/filled bowl !
    if not itemdef.soup_no_meta_transfer then
        imeta = imeta or itemstack:get_meta()
        imeta = imeta:to_table()
        if not imeta then return end -- weird error occurred, do not do anything! (couldn't turn into data table)
        minetest.set_node(pos, {name=become})
        nodemeta = nodemeta or minetest.get_meta(pos)
        nodemeta:from_table(imeta)
    else
        minetest.set_node(pos, {name=become})
    end
    empty = ItemStack(empty) -- get empty itemstack for inventory mechanics
    -- handle inventory (above does not depend on such if something was to go awry lol)
    return soup_handle_inventory(itemstack, empty, user, p_inv)
end

-- transferring node soup/stew/filled bowl to an empty bowl itemstack
local function soup_on_bowl_empty(pos, user, itemstack, p_inv, nodemeta)
    -- used for getting soup_no_meta_transfer
    local nodedef = minimal.get_nodedef(pos)
    -- get empty of soup at pos, become of empty bowl itemstack
    local empty, become = get_empty_become(itemstack, nodedef.name)
    if not (empty and become) then return end
    -- we can transfer this soup/stew/filled bowl !
    become = ItemStack(become) -- get soup/stew itemstack
    if not nodedef.soup_no_meta_transfer then
        nodemeta = nodemeta or minetest.get_meta(pos)
        nodemeta = nodemeta:to_table()
        if not nodemeta then return end -- weird error occurred, do not do anything! (couldn't turn into table)
        local imeta = become:get_meta()
        imeta:from_table(nodemeta)
    end
    minetest.set_node(pos, {name=empty})
    -- handle inventory
    return soup_handle_inventory(itemstack, become, user, p_inv)
end

-- food bowl + soup/stew functionality
-- what food bowls and soup bowls do when you click on something with them
local function soup_on_use(itemstack, user, pointed_thing, is_soup)
    local pos = pointed_thing and pointed_thing.under
    if not pos then return end
    local nodedef = minimal.get_nodedef(pos)
    local itemdef = itemstack and itemstack.get_definition and itemstack:get_definition()
    if not (itemdef and nodedef) then return end -- how you get no node or itemstack definition???
    if type(is_soup) ~= "boolean" then
        local groups = itemdef.groups
        if not groups then return end -- how??? what're you doing!!! how do we not have GROUPS!
        is_soup = (groups.stew or groups.soup or itemdef.soup_kind) and true or false
    end
    -- cooking pot interaction
    -- soupy interactions
    if is_soup then
        -- transfer soup/stew into an empty bowl
        if nodedef.on_soup_transfer then
            return nodedef.on_soup_transfer(pos, user, itemstack) or itemstack
        end
    -- empty bowl interactions
    else
    -- cooking pot or soup/stew interaction
        if nodedef.on_bowl_empty then
            return nodedef.on_bowl_empty(pos, user, itemstack) or itemstack
        end
    end
end

-- soup/stew functionality
-- preserves node meta into itemstack
local function soup_preserve_metadata(pos, oldnode, oldmeta, drops)
    oldmeta = minetest.get_meta(pos)
    local item_meta = drops[1]:get_meta()
    item_meta:from_table(oldmeta:to_table())
end

-- soup/stew functionality
-- preserves item meta into node
local function soup_after_place(pos, placer, itemstack, pointed_thing)
    local meta = minetest.get_meta(pos)
    local item_meta = itemstack and itemstack:get_meta()
    if not item_meta then return end
    meta:from_table(item_meta:to_table())
end

-- register_food_bowl_filled
-- used by register_food_bowl to register soups/stews
-- requires name, a definition, and an "empty" (a node information to revert to when transferring or eaten)
-- "empty" can be a name or a table that is similar to a node definition (expects name parameter)
-- optional food_table (table), transfer (boolean), and save_meta (boolean)
-- food_table only gets set if the filled bowl is edible and food_table is table or nil
-- transfer permits transferring between empty and filled bowls, default true unless boolean specified
-- save_meta saves the meta between transfers or when placed, default is false unless specified or edible is 2
-- name can have empty's name automatically added with "@empty"
local function register_food_bowl_filled(name, def, empty, food_table, transfer, save_meta)
    -- used for error messages
    local func_tag = "tech.register_food_bowl_filled:"
    if type(name) ~= "string" then
        error(func_tag.." expected string for name, got '"..type(name).."'")
    end
    -- whether or not we should have functions relating to the ability to transfer between bowls (true unless otherwise)
    transfer = type(transfer) ~= "boolean" and true or false
    empty = type(empty) == "table" and empty or type(empty) == "string" and core.registered_nodes[empty] or empty
    if type(empty) ~= "table" or type(empty.name) ~= "string" then
        error(func_tag.." could not get definition for empty for '"..name..
          "', not a string or valid definition table!")
    end
    -- definition check
    if type(def) ~= "table" then
        error(func_tag.." expected table for definition, got '"..type(def).."'")
    end
    -- permit option to automatically add empty bowl's name to definition name by specifying "@empty"
    if name:match("@empty") then
        -- remove empty's mod_origin from empty's name
        local modless_empty = empty.name:gsub(empty.mod_origin..":","")
        -- replace with modless_empty
        name = name:gsub("@empty", modless_empty)
    end
    -- add mod_origin to name if not provided
    def.mod_origin = core.get_current_modname()
    name = not name:match(":") and def.mod_origin..":"..name or name
    -- now to actually get to modifications we want
    -- figure out drawtype and nodebox/mesh
    def.drawtype = def.drawtype or empty.drawtype or "nodebox"
    -- replace "." with "_filled." if no mesh specified
    def.mesh = def.drawtype == "mesh" and (def.mesh or empty.mesh:gsub("%.", "_filled.")) or nil
    def.node_box = def.drawtype == "nodebox" and (def.node_box or {
        type = "fixed", fixed = table.copy(bowl_fill_box)}) or nil
    -- groups
    def.groups = def.groups or (empty.groups and table.copy(empty.groups)) or {}
    def.groups.falling_node = def.groups.falling_node or 1
    def.groups.dig_immediate = def.groups.dig_immediate or 3
    def.groups.food_bowl_filled = 1
    -- whether or not we should have functions relating to metadata
    -- dependent upon groups for alternative "true" - edible 2 will make it true if not provided
    save_meta = type(save_meta) ~= "boolean" and def.groups.edible == 2 or type(save_meta) == "boolean" and save_meta
    -- figure out if we're a soup or stew
    local soupstew = def.groups.soup and "soup" or def.groups.stew and "stew" or nil
    -- set description
    local desc_tag = def.description_tag
    def.description_tag = nil
    def.description = def.description or soupstew == "soup" and S("Bowl of @1 Soup","") or soupstew == "stew" and
        S("Bowl of @1 Stew","") or desc_tag and S("Bowl of @1", desc_tag) or name
    -- set tiles
    if not def.tiles or not def.tiles[1] then
        -- how???
        if type(empty.tiles) ~= "table" or not empty.tiles[1]then
            error(func_tag.." empty bowl '"..empty.name.."' does not have tiles!")
        end
        def.tiles = table.copy(empty.tiles)
        -- what texture will be applied on the top texture - or what will be shown for the bowl's ingredients
        -- prioritizes "filled_texture" or sets the soup texture if soup or defaults to the stew texture
        def.filled_texture = type(def.filled_texture) == "string" and def.filled_texture or
            soupstew == "soup" and "tech_soup.png" or "tech_stew.png"
        -- increase tile length to 3 if less (and if not mesh)
        if #def.tiles < 3 and not def.mesh then
            for ind, tile in pairs(def.tiles) do
                if not def.tiles[ind + 1] then
                    def.tiles[ind + 1] = type(tile) == "table" and table.copy(tile) or tile
                end
                -- just need 3 tiles, break loop
                if #def.tiles >= 3 then break end
            end
        end
        -- add soup/stew/misc texture to top of tiles
        def.tiles[1] = type(def.tiles[1]) == "table" and def.tiles[1].name.."^"..def.filled_texture or
            def.tiles[1].."^"..def.filled_texture
        def.filled_texture = nil -- clear from def
    end
    -- set inventory image if not provided
    -- do not set inventory_image if it equals to false (don't want inventory_image)
    -- otherwise looks for filled_icon or autosets to stew's icon if neither are provided
    if def.inventory_image ~= "false" and type(def.inventory_image) ~= "string" and empty.inventory_image then
        def.inventory_image = empty.inventory_image..(soupstew == "soup" and "^tech_soup_icon.png" or
            type(def.filled_icon) == "string" and "^"..def.filled_icon or "^tech_stew_icon.png")
        def.filled_icon = nil -- clear from def
        -- if wield_image isn't false, set as inventory_image, otherwise nil
        def.wield_image = def.wield_image ~= "false" and def.wield_image or
            def.inventory_image or nil
    end
    def.inventory_image = def.inventory_image ~= false and def.inventory_image or nil
    -- note empty variant
    def.soup_empty = empty.name
    -- remove group nums of less than 1
    -- ind = index or group name, grp = group number
    for ind,grp in pairs(def.groups) do
        if grp < 1 then
            def.groups[ind] = nil
        end
    end
    -- register transfer functions + functionality
    if transfer then
        -- set soup functions
        -- TODO: modify soup_on_use and soup_on_bowl_empty to have a non-meta equivalent
        def.on_use = def.on_use or soup_on_use -- used for when clicking on a node
        def.on_bowl_empty = def.on_bowl_empty or soup_on_bowl_empty -- used for when being grabbed from (being grabbed at)
        -- used for determining whether or not to save unique meta between node and itemstack
        if save_meta then
            -- save nutrition stats/unique meta
            def.preserve_metadata = def.preserve_metadata or soup_preserve_metadata
            def.after_place_node = def.ater_place_node or soup_after_place
        else
            def.soup_no_meta_transfer = true
        end
    end
    -- edible functionality
    -- only register a food table if not in HEALTH's food table already
    food_table = not HEALTH.food_table[name] and (food_table or {})
    if def.groups.edible and type(food_table) == "table" then
        -- set up food_table (add replacewithitem, eat_sound if soup)
        food_table.rwi = food_table.rwi or empty.name
        food_table.eat_sound = food_table.eat_sound or soupstew == "soup" and "nodes_nature_slurp" or nil
        -- food stats
        HEALTH.add_food_table(name, food_table)
    end
    -- consume on rightclick (if not already provided or not false and has the edible group)
    def.on_rightclick = def.on_rightclick or def.on_rightclick ~= false and def.groups.edible and
      function(pos, node, clicker, itemstack, pointed_thing)
          local ndef = core.registered_nodes[node.name]
          if not (ndef.groups and ndef.groups.edible) then return end -- not edible
          if itemstack:get_name() ~= "" then return end -- we should only eat with an empty hand
          local ft = HEALTH.food_table[node.name]
          if not ft then return end -- no food stats
          local nrpl = core.registered_nodes[ft.rwi] -- node replace, checks food table's replacewithitem
          if not nrpl then return end -- can't replace due to it not existing
          node.name = ft.rwi -- replacing using node data
          local ediblestack = ItemStack(ndef.name) -- use stack for reference
          -- playermade edible
          if ndef.groups.edible == 2 then
              local meta = core.get_meta(pos)
              local eat_value = meta:get_string("eat_value")
              meta:set_string("eat_value","") -- clear as we're consuming
              meta:set_string("description","") -- clear description
              -- transfer eat_value to ediblestack
              local imeta = ediblestack:get_meta()
              imeta:set_string("eat_value",eat_value)
              HEALTH.eatdrink_playermade(ediblestack, clicker, pointed_thing)
          -- regular edible
          else
              HEALTH.eatdrink(ediblestack, clicker, pointed_thing)
          end
          -- play eating sound
          local eat_sound = ft.eat_sound
          minimal.switch_node(pos, node) -- save any meta
      end or nil
    -- misc extra stuff
    def.paramtype = def.paramtype or empty.paramtype or "light"
    def.sounds = def.sounds or empty.sounds and table.copy(empty.sounds) or nodes_nature.node_sound_defaults()
    def.stack_max = def.stack_max or empty.stack_max
    -- register node and return name
    core.register_node(name, def)
    return name
end
-- namespace
tech.register_food_bowl_filled = register_food_bowl_filled

local function register_food_bowl(name, def)
    assert(type(name) == "string",
        "tech.register_food_bowl: got non-string for name, got type '"..type(name).."'")
    -- permit lazy lack of definition
    def = type(def) == "table" and def or {}
    -- fix name properly
    -- colon at first part of string, indicative of no modname
    -- no colon, no mod name or colon associated, add one
    local mod_origin = minetest.get_current_modname()
    name = not name:match(":") and mod_origin..":"..name or name
    def.name = name -- needed for register_food_bowl_filled
    -- figure out variant
    def.bowl_variant = (type(def.bowl_variant) == "string" and def.bowl_variant:lower()) or "clay"
    local variant = def.bowl_variant
    -- base def
    def.stack_max = def.stack_max or minimal.stack_max_medium
    def.paramtype = def.paramtype or "light"
    def.description = def.description or S("Empty Bowl")
    -- base groups
    def.groups = def.groups or {}
    def.groups.dig_immediate = def.groups.dig_immediate or 3
    def.groups.falling_node = def.groups.falling_node or 1
    def.groups.food_bowl = 1
    -- dependent on variant
    def.groups.pottery = def.groups.pottery or (variant == "clay" and 1) or nil
    def.groups.flammable = def.groups.flammable or (variant == "wooden" and 2) or nil
    def.sounds = def.sounds or (variant == "wooden" and nodes_nature.node_sound_wood_defaults() or
        tech.node_sound_earthenware_defaults())
    def.tiles = def.tiles or (variant == "wooden" and "tech_primitive_wood.png" or "tech_pottery.png")
    -- convert to tile table
    def.tiles = type(def.tiles) == "string" and {def.tiles} or def.tiles
    -- if variant is wooden or clay, find tech_food_bowl icon variants
    -- if variant is custom, check for modname _food_bowl icon variants
    def.inventory_image = def.inventory_image or variant and ( (variant == "wooden" or variant == "clay") and
        "tech_food_bowl_"..variant.."_icon.png" or mod_origin.."_food_bowl_"..variant.."_icon.png") or nil
    -- set wield image to inventory_image
    def.wield_image = def.wield_image or def.inventory_image
    -- nodebox
    def.drawtype = def.drawtype or "nodebox"
    def.node_box = def.node_box or def.drawtype == "nodebox" and
        {type = "fixed", fixed = bowl_box} or nil
    -- functions
    def.on_use = def.on_use or soup_on_use
    --------------- soup and stew variants
    def.soup_to = def.soup_to or def.soup_to ~= false and "_soup" or nil
    def.stew_to = def.stew_to or def.stew_to ~= false and "_stew" or nil
    if type(def.soup_to) == "string" or type(def.soup_to) == "table" then
        -- figure out name lol
        local soup = def.soup_to
        soup = soup == "_soup" and name.."_soup" or soup
        soup = type(soup) == "string" and {name=soup} or soup
        soup.name = soup.name or name.."_soup"
        soup.groups = soup.groups or table.copy(def.groups)
        soup.groups.soup = 1
        soup.groups.edible = 2
        def.soup_to = register_food_bowl_filled(soup.name, soup, def)
    end
    if type(def.stew_to) == "string" or type(def.stew_to) == "table" then
        -- figure out name lol
        local stew = def.stew_to
        stew = stew == "_stew" and name.."_stew" or stew
        stew = type(stew) == "string" and {name=stew} or stew
        stew.name = stew.name or name.."_stew"
        stew.stew = true
        stew.groups = stew.groups or table.copy(def.groups)
        stew.groups.stew = 1
        stew.groups.edible = 2
        def.stew_to = register_food_bowl_filled(stew.name, stew, def)
    end
    -- final touches to the empty bowl
    def.on_soup_transfer = def.on_soup_transfer or soup_transfer
    minetest.register_node(name,def)
end
-- namespace
tech.register_food_bowl = register_food_bowl

-- registration of clay + wooden food bowls, and their soup + stew variants
register_food_bowl("food_bowl_clay")
register_food_bowl("food_bowl_wooden",{
    bowl_variant = "wooden"
})
minetest.register_alias_force("tech:soup","tech:food_bowl_clay_soup")

-- freshwater variants of bowls
-- clay
register_food_bowl_filled("food_bowl_clay_freshwater",{
    description = S("Bowl of Freshwater"),
    filled_texture = "tech_bowl_water.png",
    filled_icon = "tech_bowl_water_icon.png",
    groups = {edible=1, no_soup=1, drink=1},
    use_texture_alpha = minimal.compat_alpha and minimal.compat_alpha.clip,
    -- empty is food_bowl_clay
    }, "tech:food_bowl_clay",
    -- food table
    {
        th = 5,
        eat_sound = "nodes_nature_slurp"
    }
)
-- wooden
register_food_bowl_filled("food_bowl_wooden_freshwater",{
    description = S("Bowl of Freshwater"),
    filled_texture = "tech_bowl_water.png",
    filled_icon = "tech_bowl_water_icon.png",
    groups = {edible=1, no_soup=1, drink=1},
    use_texture_alpha = minimal.compat_alpha and minimal.compat_alpha.clip,
    -- empty is food_bowl_clay
    }, "tech:food_bowl_wooden",
    -- food table
    {
        th = 5,
        eat_sound = "nodes_nature_slurp"
    }
)

-- # TODO: add options for more or less slots
local function get_formspec()
    local pot_formspec = "size[8,4.1]"..
        "list[current_name;main;0,0;8,2]"..
        "list[current_player;main;0,2.3;8,4]"..
        "listring[current_name;main]"..
        "listring[current_player;main]"
    return pot_formspec
end

-- miscellaneous pot functions

-- status: "" = unprepared, then: prepared (water), cooking/cooling, finished
-- clear pot function
-- clears all meta, refreshes formspec
local function clear_pot(pos)
    minetest.get_node_timer(pos):stop()
    local ndef = minimal.get_nodedef(pos)
    if not ndef then return end -- can't do anything with a nil node
    local meta = minetest.get_meta(pos)
    meta:from_table() -- clear out meta
    minimal.infotext_set_new(pos, meta, nil, nil, ndef)
    local inv = meta:get_inventory()
    inv:set_size("main", 8)
end

-- get percent of total per each soup bowl
-- percent must be 1-100
local function get_eat(total, percent, serialize)
    percent = type(percent) == "number" and percent or 10 -- default percentage of 10
    if (percent < 1 or percent > 100) then return end -- maybe do an error instead
    serialize = type(serialize) ~= "boolean" and true or serialize
    percent = math.ceil(percent) -- no decimals
    local result = {}
    -- iterate over stats, only do calculation if number
    for stat,value in pairs(total) do
        if type(value) == "number" then
            -- floor to get a reasonable integer
            result[stat] = math.floor(value * (percent/100))
        end
    end
    -- serialize if not otherwise specified
    result = serialize and minetest.serialize(result) or result
    return result
end

-- give a number on how long it should take to cook the stack
local function calc_baking_time(stack,count)
    -- #TODO: Check if we're adding to a stack, don't alter
    local fname = stack:get_name()
    local bake_data = HEALTH.bake_table[fname]
    -- get baking time or 1 if already cooked
    local time = bake_data and bake_data.duration or fname:match("_cooked") and 1 or nil
    if not time then
        -- no time, let's check some stuff
        local ft = HEALTH.get_food_stats(fname)
        if not ft then return 0 end -- has no time to give (not a food? how?)
        local sdef = stack:get_definition() -- stackdef
        -- check if has the group 'cooked', set as 1 similarly to above cooked
        -- then use group 'baking_time' if exists if not above
        -- otherwise use half of nutrition unit value
        time = sdef.groups and (sdef.groups.cooked and 1 or sdef.groups.baking_time) or
            1 + math.floor(math.abs(ft.hu/2))
    end
    count = count or stack:get_count()
    local max_count = stack:get_stack_max()
    -- divide_multiplier: ensure to get a number that doesn't go below 1
    -- we basically check what number would be fair to utilize for quantity calculation
    -- 4 is used as a predictive base as using max_count wouldn't do mass as fairly
    -- we wouldn't want to do count/4 if the max_count is 2, as this'd make it easier to cook
    -- so we do a baseline of 4 or the max_count, only an issue with any items with a max_count less than 4
    local divide_multiplier = (max_count > 3 and 4 or max_count)

    -- calculate time by quantity
    -- use item count divided by a max_count that's divided by +1 multiplier as a safe guess to the total mass
    -- minimum of 1 for time
    return time * math.max(count / (max_count / divide_multiplier),1)
end

-- adjust baking
-- ran in pot_on_receive_fields using the total time's worth from all provided ingredients
-- calculates a difference from subtracting the total by current baking, adds to adjusting values
-- adjusts two values - baking and "base_baking" 
-- "base_baking" is used to determine what the pot should "uncook" back to when opened
local function adjust_baking(meta, total)
    if type(total) ~= "number" then return end
    local b_bake = meta:get_int("base_baking")
    if b_bake == 0 then
        meta:set_int("base_baking", total)
        meta:set_int("baking", total)
        return
    end
    -- we don't need to modify meta and do calculationes
    if total == b_bake then return end
    local bake = meta:get_int("baking")
    local dif = total - b_bake
    b_bake = b_bake + dif
    bake = bake + dif
    meta:set_int("base_baking", b_bake)
    meta:set_int("baking", bake)
end

-- On dig, ask if the player wants to dump the pot, losing the contents
local function spill_pot(returnedyes, data, player, playername)
    if returnedyes then
        local pot = minetest.get_node(data.spillpos)
        local potmeta = minetest.get_meta(data.spillpos)
        potmeta:set_string("type", "")
        minetest.node_dig(data.spillpos, pot, player)
    end
end

-- spawn steam particles
-- pos, amount, timedelay
local function spawn_steam(pos,def)
    local ndef = minimal.get_nodedef(pos)
    -- utilize collision box for proper node interactions
    local collbox = ndef.collision_box or {-0.5,-0.5,-0.5, 0.5,0.5,0.5}
    def = def or {}
    def.amount = def.amount or def.amt or random(6,10)
    if type(def.amount) == "table" then -- randomize
        def.amount = random(def.amount[1],def.amount[2])
    end
    def.animation = {
        type = "vertical_frames",
        aspect_w = 16,
        aspect_h = 16,
        length = 1.1, -- 11 frames, 0.1s/ea
    }
    def.time = def.time or 7 -- a second more than the node timer
    def.glow = def.glow or 4
    def.minsize = def.minsize or 10
    def.maxsize = def.maxsize or 10
    def.collisiondetection = true
    def.vertical = true
    def.minexptime = def.minexptime or 1
    def.maxexptime = def.maxexptime or 1
    -- is iterated through for variations
    local spawnpos = {
        {
            x = (pos.x + collbox[1]),
            vel = {x={0.2,0.7}}
        },
        {
            x = (pos.x + collbox[4]),
            vel = {x={-0.2,-0.7}}
        },
        {
            z = (pos.z + collbox[3]),
            vel = {z={0.2,0.7}}
        },
        {
            z = (pos.z + collbox[6]),
            vel = {z={-0.2,-0.7}}
        }
    }
    local denied = 0 -- utilized to determine how many spawnpos variants are ignored
    for i,spinfo in pairs(spawnpos) do
        def.texture = "tech_steam_particles.png^[opacity:"..random(160,255)
        -- allow particle pos customization with spawnpos
        local ppos = {x=(spinfo.x or pos.x),y=(pos.y+collbox[5]),z=(spinfo.z or pos.z)}
        ppos.x = {ppos.x-0.1,ppos.x+0.1}
        ppos.y = {ppos.y-0.3,ppos.y+0.1}
        ppos.z = {ppos.z-0.1,ppos.z+0.1}
        local vel = spinfo.vel
        if denied > 2 or random() >= 0.5 then -- if more than 2 ignored variants or if 50%
            -- get or create min-max velocity system
            vel.x = vel.x or {0,0}
            vel.y = vel.y or {0.2,1}
            vel.z = vel.z or {0,0}
            -- set raw values
            def.minpos = {x=ppos.x[1],y=ppos.y[1],z=ppos.z[1]}
            def.maxpos = {x=ppos.x[2],y=ppos.y[2],z=ppos.z[2]}
            def.minvel = {x=vel.x[1],y=vel.y[1],z=vel.z[1]}
            def.maxvel = {x=vel.x[2],y=vel.y[2],z=vel.z[2]}
            minetest.add_particlespawner(def)
        else -- add to denied
            denied = denied + 1
        end
    end
end

-- functionality for determining if a player is looking in a pot
-- look at minimal/storage_watcher_api.lua for more info
local get_watchers = minimal.get_watchers
local add_watcher = minimal.add_watcher
local remove_watcher = minimal.remove_watcher


-- PRIMARY POT FUNCTIONS

-- pot_rightclick - what happens when you open the pot!
local function pot_rightclick(pos, node, clicker, itemstack, pointed_thing)
    if not minetest.is_player(clicker) then return end
    local meta = minetest.get_meta(pos)
    local fspec = meta:get_string("formspec")
    -- likely pot hasn't started or is finished, return
    if fspec == "" then return end -- can't even access the formspec!
    -- opening pot
    -- play a sound if we're the first to open the pot
    if #get_watchers(pos) == 0 then
        local ndef = minetest.registered_nodes[node.name]
        -- get or create sound for pot open
        local sound = ndef.sounds and ndef.sounds.pot_open
        sound = sound and table.copy(sound) or {
            name = "tech_clay_storage_open",
            gain = 0.4,
            max_hear_distance = 14
        }
        sound.pos = pos
        minetest.sound_play(sound.name, sound)
    end
    add_watcher(pos, clicker)
end

-- fix compatibility with older pot system
local function pot_compatibility(meta, inv, inv_main)
    inv = inv or meta:get_inventory()
    inv_main = inv_main or inv:get_list("main")
    -- get soup description
    local soup_desc = inv_main[1]:get_description()
    -- update pot and fix da mess
    meta:set_string("soup_desc", soup_desc)
    local soup_perc = inv_main[1]:get_count()*10 -- times by 10 to get expected percentage
    -- was an itemstack of 10 soups, so use that for expected calculation ^
    meta:set_int("soup_percent", soup_perc)
    inv:set_size("main", 0) -- delete inventory
    meta:set_string("formspec","") -- delete formspec
    -- return results for use: description, percentage
    return soup_desc, soup_perc
end

-- receive fields, what happens when player closes the formspec
-- if ingredients are added:
-- ;timer is set or restarted if inactive here
-- ;note is changed to be nil
-- ;baking meta is set
-- plays close sound
local function pot_receive_fields(pos, formname, fields, sender)
    local meta = minetest.get_meta(pos)
    if minetest.is_protected(pos, sender, meta) then return end

    local ndef = minimal.get_nodedef(pos) -- used to get sounds and for infotext setting
    -- closing pot, 1 less player looking inside (done purposefully before all return checks)
    -- play a sound if we're the last to close the pot
    remove_watcher(pos, sender)
    if #get_watchers(pos) == 0 then
        -- get or create sound for pot close
        local sound = ndef.sounds and ndef.sounds.pot_close
        sound = sound and table.copy(sound) or {
            name = "tech_clay_storage_close",
            gain = 0.4,
            max_hear_distance = 14
        }
        sound.pos = pos
        minetest.sound_play(sound.name, sound)
    end

    local inv = meta:get_inventory()
    local inv_main = inv:get_list("main")
    if not inv_main then -- this is a bugged pot from before commit 851e0ec744
        return clear_pot(pos) -- return and fix it!
    end
    -- return if inventory is empty (add your ingredients lol)
    if inv:is_empty("main") then
        meta:set_string("pot_contents","")
        return
    end
    -- total worth of satiation
    local water_type = meta:get_string("water_type")
    local total = {hp=0,th=0,hu=0,en=0}
    local contents = {} -- table containing list of pot contents
    if water_type == 'nodes_nature:freshwater_source' then -- regular water
        total.th = 100
        contents = {S("Water")}
    elseif water_type == 'nodes_nature:saltwater_source' then -- saltwater, NOT YET IMPLEMENTED
    end
    local time = ndef.cook_base_baking or 1
    -- calculating satiation worth of all items
    for index, item in pairs(inv_main) do
        local stats = HEALTH.get_food_stats(item, true) -- second parameter: prefer cooked, raw if none
        if stats then -- only make calculations if stats are found
            local count = item:get_count()
            time = time + calc_baking_time(item, count)
            for stat,value in pairs(stats) do
                if total[stat] then -- prevent temp from being changed lol
                  total[stat] = total[stat] + (value * count)
                end
            end
            -- add to contents table
            contents[#contents + 1] = item:get_short_description()
        -- compatibility with old pot system, otherwise resume as normal
        elseif index == 1 and item:get_name() == "tech:food_bowl_clay_soup" then
            pot_compatibility(meta, inv, inv_main)
        -- hey, you shouldn't be in here! throw it out!
        else
            minetest.add_item(minimal.pos_shift(pos,{y=1}), item)
            inv:set_stack("main", index, "") -- clear out from inventory
        end
    end
    -- no contents in the pot, do not adjust baking or modify infotext
    if #contents < 2 then return end
    -- restart timer if there's issues (or start it)
    local timer = minetest.get_node_timer(pos)
    -- timer died, run it again
    if not timer:is_started() then
        timer:start(6)
    end
    adjust_baking(meta, time)
    -- convert to string
    contents = table.concat(contents, ", ")
    -- for infotext
    meta:set_string("contents_string",S("Contents: @1",contents))
    meta:set_string("note","nil") -- clear note about adding food
    -- pos, meta, meta_params, custom_func, nodedef
    minimal.infotext_set_new(pos, meta, nil, nil, ndef)
    -- set soup satiation
    meta:set_string("pot_contents", minetest.serialize(total))
end

local function pot_cook(pos, elapsed)
    local meta = minetest.get_meta(pos)
    -- node definition used to get name, sounds, and determine portions
    local ndef = minimal.get_nodedef(pos)
    -- commit heat transfer
    climate.heat_transfer(pos, ndef.name)
    local temp = climate.get_point_temp(pos)
    -- meta variables
    local kind = meta:get_string("type")
    local baking = meta:get_int("baking")
    local status = meta:get_string("status")
    -- set up sounds
    local sounds = ndef.sounds or {}
    -- fix weird changed timeout bug?
    if status == "" then return end

    -- soup done
    if status == "finished" then
      return -- just end the timer for now
      -- Handle burning food here
      --TODO: burned: reduce the value of pot_contents, emit more smoke
    -- let's do some cooking checks
    else
        local inv = meta:get_inventory()
        local inv_main = inv:get_list("main")
        local opened = #get_watchers(pos) > 0
        -- basically means we're workin on a nice yummy treat
        if kind == "Soup" then
            -- finished cooking
            if baking <= 0 then
                -- get pot contents table (satiation total)
                local total = minetest.deserialize(meta:get_string("pot_contents"))
                local firstingr -- first ingredient (used to determine name of soup)
                -- we got ourselves odd soup if there's no total
                if total then
                    for _,ingr in pairs(inv_main) do
                        -- get first ingredient
                        if ingr:get_short_description() ~= "" then
                            firstingr = ItemStack(ingr) -- get the itemstack for further assessment
                            break -- end loop
                        end
                    end
                    -- get description of first ingredient
                    if firstingr then
                        local name = firstingr:get_name()
                        local bake_var = HEALTH.bake_table[name]
                        -- get description of the cooked variant
                        if bake_var then
                            name = bake_var.cooked or name.."_cooked"
                            if minetest.registered_items[name] then
                                firstingr = ItemStack(name)
                            end
                        end
                        firstingr = firstingr:get_short_description()
                    end
                else
                    -- ooOOOOooo mysterious soup! Let's give players a bonus for breaking the game lol
                    total = {hp=10,th=100,hu=70,en=20}
                    -- permit ability to grab soup from
                    meta:set_string("pot_contents",minetest.serialize(total))
                end
                firstingr = firstingr or "Odd"
                -- setting of variables + backwards compatibility for old table system
                -- 1, 2, 3, 4 - or hp, th, hu, en
                for i,val in pairs({"hp","th","hu","en"}) do
                    total[val] = total[val] or total[i]
                end
                -- complete final steps
                spawn_steam(pos,{amt={22,45}})
                if sounds.frying_final then
                    minimal.sound_play(minimal.merge_tables(sounds.frying_final,{pos = pos}))
                end
                -- stew is when hunger content is greater than thirst content
                kind = total.hu > total.th and "Stew" or kind
                -- remove formspec + inventory, set percentage
                meta:set_string("formspec","")
                inv:set_size("main", 0)
                meta:set_int("soup_percent",100)
                -- set as finished
                meta:set_string("status", "finished")
                -- set kind again for soup/stew
                if kind == "Stew" then meta:set_string("type",kind) end
                -- get proper description
                local desc = S(
                  "Bowl of @1 "..(kind == "Stew" and "Stew" or "Soup"),firstingr
                )
                meta:set_string("soup_desc", desc) -- used to name gotten soup
                inv:set_list("main", inv_main)
                -- set infotext
                meta:set_string("contents_string",S("Contents: @1",desc))
                meta:set_string("status_string",S("Status: @1 pot (finished)",S(kind)))
                -- pos, meta, meta_params, custom_func, nodedef
                minimal.infotext_set_new(pos, meta, nil, nil, ndef)
            -- we're gonna cook!
            elseif temp >= 100 then
                if inv:is_empty("main") then return end -- no inventory weird
                -- not cooking already, let's get to it!
                if status ~= 'cooking' then
                    meta:set_string('status', 'cooking')
                    meta:set_string('status_string',S("Status: @1 pot (cooking)", S(kind)))
                    minimal.infotext_set_new(pos, meta, nil, nil, ndef)
                    spawn_steam(pos,{amt={14,24}})
                    if sounds.frying_start then
                        minimal.sound_play(minimal.merge_tables(sounds.frying_start,{pos = pos}))
                    end
                    return true
                -- already cookin'
                else
                    -- lots of steam if opened
                    spawn_steam(pos, opened and {amt={22,40}} or nil)
                    if sounds.frying then
                        -- play a sound indicating we're opened!
                        if opened and sounds.frying_open then
                            minimal.sound_play(minimal.merge_tables(sounds.frying_open,{pos = pos}))
                        -- play as normal
                        else
                            minimal.sound_play(minimal.merge_tables(sounds.frying,{pos = pos}))
                        end
                    end
                end
                baking = baking - 1
            -- too cold
            elseif temp < 100 then
                if status ~= 'prepared' and status ~= 'cooling' then
                    meta:set_string("status", "cooling")
                    meta:set_string("status_string",S('Status: @1 pot', S(kind)))
                    minimal.infotext_set_new(pos, meta, nil, nil, ndef)
                end
            end -- baking/temp if statements
            -- check if we should decrease baking
            if baking >= 0 then
                -- someone's peepin!
                if opened then
                    local base_baking = meta:get_int("base_baking")
                    -- only increase baking if base_baking is over 4, and if baking is less than base_baking minus 2
                    if base_baking >= 4 and (baking <= (base_baking-2)) then
                      baking = baking + random(1,2) -- add 1 to 2
                    end
                end
                -- now set baking
                meta:set_int("baking",baking)
            end
        
      end -- 'kind' if statement
  end -- 'finished' if statement
  return true
end

minetest.register_node("tech:cooking_pot",{
    description = S("Cooking Pot"),
    tiles = {"tech_pottery.png",
    "tech_pottery.png",
    "tech_pottery.png",
    "tech_pottery.png",
    "tech_pottery.png"},
    drawtype = "nodebox",
    stack_max = minimal.stack_max_bulky,
    paramtype = "light",
    paramtype2 = "facedir",
    node_box = {
        type = "fixed",
        fixed = pot_box
    },
    groups = {dig_immediate = 3, pottery = 1, cooking_pot = 1, heatable = 75 },
    sounds = tech.node_sound_earthenware_defaults(tech.interact_sound_cooking_vessel()),
    on_construct = clear_pot,
    on_rightclick = pot_rightclick,
    on_timer = pot_cook,
    on_dig = function(pos, node, digger)
        if not minetest.is_player(digger) then return end
        local playername = digger:get_player_name()
        local meta = minetest.get_meta(pos)
        if minetest.is_protected(pos, playername, meta) then
            return false
        end
        local inv = meta:get_inventory()
        local pottype = meta:get_string("type")
        if ( not inv:is_empty("main")
             or pottype ~= "") then -- type is empty on uprepared pot
            minimal.yes_or_no(playername,
                              S("This pot is full and heavy. "..
                                "Spill it?"), spill_pot,
                              { spillpos = pos } )
            return false
        end
        minetest.node_dig(pos, node, digger)
    end,
    -- inventory functions
    on_receive_fields = pot_receive_fields,
    allow_metadata_inventory_put = function(pos, listname, index, stack, player)
        local stackdef = stack:get_definition()
        -- can't be added to soup (edible == 2 or is no_soup)
        if stackdef.groups and
            (stackdef.groups.no_soup and stackdef.groups.no_soup > 0 or stackdef.groups.edible == 2) then
            return 0
        end
        -- not a valid food or cookable
        if not HEALTH.food_table[stackdef.name] and
            not HEALTH.bake_table[stackdef.name] then
            return 0
        end
        local meta = minetest.get_meta(pos)
        if minetest.is_protected(pos, player, meta) then return 0 end
        -- prevent adding items after cooking is complete
        if meta:get_string("status") == "finished" then
          return 0
        end
        local inv = meta:get_inventory():get_list(listname)
        local count = stack:get_count()
        -- check through pot inventory
        for i,item in pairs(inv) do
            -- Only 1 stack of a given item at a time
            if item:get_name() == stack:get_name() then
                -- can we fit into this index?
                if i == index then
                    -- if count is greater than available space, subtract to
                    count = math.min(item:get_stack_max() - item:get_count(), count)
                    if count <= 0 then return 0 end -- can't actually add anymore
                    break
                else
                    return 0
                end
            end
        end
        return count
    end,
    allow_metadata_inventory_take = function(pos, listname, index, stack, player)
        local meta = minetest.get_meta(pos)
        if minetest.is_protected(pos, player, meta) then return 0 end
        local status = meta:get_string("status")
        -- is cooking or already cooked, no takey
        if status ~= "" and status ~= "prepared" then
            return 0
        end
        -- ok you're allowed to take
        local count = stack:get_count()
        return count
    end,
    on_infotext = function(pos, nodedef, meta, params)
        params = minimal.infotext_update_params(meta, params)
        params.description = nodedef.description -- don't get description in get_base_params
        -- get proper owner string
        params = minimal.infotext_get_base_params(nil, meta, params)
        -- get base status'
        params.status_string = params.status_string or S("Unprepared Pot")
        params.contents_string = params.contents_string or S("Contents: <EMPTY>")
        params.note = params.note or S("Note: Add water to pot to make soup")
        if params.note == "nil" then params.note = nil end -- no note to add
        -- percentage system + note to get soup with a bowl
        if params.status == "finished" then
            local leftover = params.soup_percent or 100
            params.note = S("Note: Use a Bowl to Get!").."\n"..
                S("Leftover: @1%",leftover)
        end
        -- prioritize in order:
        -- status_string, owner, contents, note
        return params.status_string..(params.owner and params.owner ~= "" and "\n"..params.owner or "")..
            "\n"..params.contents_string..(params.note and "\n"..params.note or "")
    end,
    -- liquid_store_pourin callback
    -- so we don't need to set up functionality for water in pot_rightclick
    ls_pourin = function(itemstack, user, pos, source, selfdef)
        -- not even water we can use! return!
        if source ~= "nodes_nature:freshwater_source" then return itemstack end
        local meta = minetest.get_meta(pos)
        if meta:get_string("status") ~= "" then return itemstack end -- pot is active, return
        -- it's soupin' time
        meta:set_string("type","Soup")
        meta:set_string("status","prepared") -- between water and ingredients, and cooling/cooking/finished
        meta:set_string("water_type",source) -- set water type
        meta:set_string("status_string",S("Soup Pot"))
        meta:set_string("contents_string",S("Contents: @1",S("Water")))
        meta:set_string("note",S("Note: Add food to the pot to make soup"))
        minimal.infotext_set_new(pos, meta, nil, nil, selfdef)
        meta:set_string("formspec", get_formspec())
        -- play pour sounds if provided
        local pourdef = itemstack:get_definition()
        if pourdef and pourdef.sounds and pourdef.sounds.pour then
            local sound = pourdef.sounds.pour
            minimal.sound_play(minimal.merge_tables(sound,{pos = pos}))
        end
        -- drain or keep pot depending on if in creative
        if not minimal.player_in_creative(user) then
            return liquid_store.drain_store(user, itemstack)
        end
        return itemstack
        -- TODO: use oil for fried food, saltwater for salted food (to preserve it)
        -- TODO: add salt effect to soup, lessened water
        -- XXX Was going to add ability to take water out of a prepared pot but more complicated
        -- then expected will try again later
        -- TPH: just see about using ls_fillup! :D ^^^
    end,
  -- custom functions
  -- used for filling up a bowl
  on_bowl_empty = function(pos, user, itemstack, meta, u_inv)
      local itemdef = itemstack:get_definition()
      -- needs to be able to become soup or stew, otherwise return
      if not itemdef or not (itemdef.soup_to or itemdef.stew_to) then return end
      meta = meta or minetest.get_meta(pos)
      -- if cooking pot isn't done then there's no soup to get!
      if meta:get_string("status") ~= "finished" then return end
      local kind = meta:get_string("type")
      local become = soup_get_become(itemdef, kind)
      if not become then return end -- could not get soup/stew variant
      -- no soup to get, return
      if meta:get_string("pot_contents") == "" then return end
      -- clicker needs an inventory
      u_inv = u_inv or (user and user.get_inventory and user:get_inventory()) -- user inventory
      if not u_inv then return end
      -- get nutrition data
      local total = minetest.deserialize(meta:get_string("pot_contents"))
      if not total then return end -- could not get
      -- soup_description, soup_percentage
      local soup_desc = meta:get_string("soup_desc")
      local soup_perc = meta:get_int("soup_percent")
      -- old pot system, let's fix this mess! (compatibility)
      if soup_desc == "" then
          soup_desc, soup_perc = pot_compatibility(meta)
      end
      -- aint no soup! clear!
      if soup_perc < 1 then
          return clear_pot(pos)
      end
      -- determine how much to take for soup
      local take_perc = itemdef.soup_capacity or 10
      -- ensure take_perc is within limits of current soup_perc
      take_perc = math.min(take_perc, soup_perc)
      local eat = get_eat(total, take_perc)

      -- set up soup bowl for player
      become = ItemStack(become)
      local becmeta = become:get_meta()
      becmeta:set_string("eat_value", eat)
      becmeta:set_string("description", soup_desc)
      -- modify pot data on success
      local function modify_pot()
          -- calculate new soup_perc
          soup_perc = soup_perc - take_perc
          -- reset pot upon full clearing
          if soup_perc < 1 then
              clear_pot(pos)
          else -- otherwise lower soup percent
              meta:set_int("soup_percent", soup_perc)
              minimal.infotext_set_new(pos, meta)
          end
      end
      -- inventory management
      local plr_creative = minimal.player_in_creative(user)
      local deplete_bowl = false
      -- original itemstack cannot be replaced (more than 1 or player in creative)
      if itemstack:get_count() > 1 or plr_creative then
          if u_inv:room_for_item("main",become) then
              deplete_bowl = not plr_creative and true
              u_inv:add_item("main",become)
              modify_pot()
          -- no room, abort
          else
              minimal.warn_inv_full(user)
          end
      -- last bowl used, replace instead
      else
          itemstack = become
          modify_pot()
      end
      -- only take away 1 bowl if can deplete
      if deplete_bowl then
          itemstack:take_item()
      end
      return itemstack
  end
})

minetest.register_node(
    "tech:cooking_pot_unfired", {
        description = S("Cooking Pot (unfired)"),
        tiles = {"nodes_nature_clay.png",
                 "nodes_nature_clay.png",
                 "nodes_nature_clay.png",
                 "nodes_nature_clay.png",
                 "nodes_nature_clay.png",
                 "nodes_nature_clay.png"},
        drawtype = "nodebox",
        stack_max = minimal.stack_max_bulky,
        paramtype = "light",
        paramtype2 = "facedir",
        node_box = {
            type = "fixed",
            fixed = pot_box,
        },
        groups = {dig_immediate=3, temp_pass = 1,
                  falling_node = 1, heatable = 20},
        sounds = nodes_nature.node_sound_stone_defaults(),
        on_construct = function(pos)
            ncrafting.set_firing(pos, ncrafting.base_firing,
                                 ncrafting.firing_int)
        end,
        on_dig = function(pos, node, digger)
            return ncrafting.on_dig_pottery(pos, node, digger,
                                            ncrafting.base_firing)
        end,
        on_timer = function(pos, elapsed)
            --finished product, length
            return ncrafting.fire_pottery(pos, "tech:cooking_pot_unfired",
                                          "tech:cooking_pot",
                                          ncrafting.base_firing)
        end,

})

crafting.register_recipe({
        type = {"crafting_spot","hand_pottery"},
        output = "tech:cooking_pot_unfired 1",
        items = {"nodes_nature:clay_wet 3"},
        level = 1,
        always_known = true,
})
crafting.register_recipe({
        type = {"mixing_spot","hand_pottery"},
        output = "nodes_nature:clay 3",
        items = {"tech:clay_water_pot_unfired 1"},
        level = 1,
        always_known = true,
})

-- soup bowl crafts
minetest.register_node(
    "tech:food_bowl_clay_unfired", {
        description = S("Bowl (unfired)"),
        tiles = {"nodes_nature_clay.png",
                 "nodes_nature_clay.png",
                 "nodes_nature_clay.png",
                 "nodes_nature_clay.png",
                 "nodes_nature_clay.png",
                 "nodes_nature_clay.png"},
        drawtype = "nodebox",
        stack_max = minimal.stack_max_medium,
        paramtype = "light",
        node_box = {
            type = "fixed",
            fixed = bowl_box,
        },
        groups = {dig_immediate=3, --temp_pass = 1,
                  falling_node = 1, heatable = 1},
        sounds = nodes_nature.node_sound_stone_defaults(),
        on_construct = function(pos)
            ncrafting.set_firing(pos, math.floor(ncrafting.base_firing*0.25),
                                 ncrafting.firing_int)
        end,
        on_dig = function(pos, node, digger)
            return ncrafting.on_dig_pottery(pos, node, digger,
                                            math.floor(ncrafting.base_firing*0.25))
        end,
        on_timer = function(pos, elapsed)
            --finished product, length, temperature
            --it'd be more realistic for the temp to be 440+, but sometimes we have to suspend reality for convenience
            return ncrafting.fire_pottery(pos, "tech:food_bowl_clay_unfired",
                                          "tech:food_bowl_clay",
                                          math.floor(ncrafting.base_firing*0.25), 250)
        end,

})

crafting.register_recipe({
        type = {"crafting_spot","hand_pottery"},
        output = "tech:food_bowl_clay_unfired 3",
        items = {"nodes_nature:clay_wet"},
        level = 1,
        always_known = true,
})
crafting.register_recipe({
        type = {"mixing_spot","hand_pottery"},
        output = "nodes_nature:clay",
        items = {"tech:food_bowl_clay_unfired 4"},
        level = 1,
        always_known = true,
})
-- wooden bowl
crafting.register_recipe({
        type = {"axe"},
        output = "tech:food_bowl_wooden 3",
        items = {"group:hard_wood", "tech:vegetable_oil 2"},
        level = 1,
        always_known = true,
})
-- more advanced crafting station
crafting.register_recipe({
        type = {"carpentry_bench"},
        output = "tech:food_bowl_wooden 5",
        items = {"group:hard_wood", "tech:vegetable_oil 3"},
        level = 1,
        always_known = true,
})

-- divide water pots into bowls
for _, water in pairs({"tech:wooden_water_pot_freshwater", "tech:clay_water_pot_freshwater"}) do
    local empty = liquid_store.get_sl_def(water).nodename_empty
    crafting.register_recipe({
        type = {"hand_mixing"},
        output = "tech:food_bowl_clay_freshwater 20",
        items = {water, "tech:food_bowl_clay 20"},
        replace = empty,
        sound = {name="liquid_store_water_pour", pitch = {0.85,1.05},
          gain = {0.1,0.25}, max_hear_distance = 8}
    })
    crafting.register_recipe({
        type = {"hand_mixing"},
        output = "tech:food_bowl_wooden_freshwater 20",
        items = {water, "tech:food_bowl_wooden 20"},
        replace = empty,
        sound = {name="liquid_store_water_pour", pitch = {0.85,1.05},
          gain = {0.1,0.25}, max_hear_distance = 8}
    })
end
-- pour 20 bowls into an empty pot
for _,filled in pairs({"tech:food_bowl_clay_freshwater", "tech:food_bowl_wooden_freshwater"}) do
    local def = core.registered_nodes[filled]
    -- 1=filled bowls (to be emptied), 2=empty bowls (result of emptying)
    local amts = {table.concat({filled," 20"}), table.concat({def.soup_empty," 20"})}
    crafting.register_recipe({
        type = {"hand_mixing"},
        output = "tech:clay_water_pot_freshwater",
        items = {"tech:clay_water_pot", amts[1]},
        replace = amts[2],
        sound = {name="liquid_store_water_pour", pitch = {0.85,1.05},
          gain = {0.1,0.25}, max_hear_distance = 8}
    })
    crafting.register_recipe({
        type = {"hand_mixing"},
        output = "tech:wooden_water_pot_freshwater",
        items = {"tech:wooden_water_pot", amts[1]},
        replace = amts[2],
        sound = {name="liquid_store_water_pour", pitch = {0.85,1.05},
          gain = {0.1,0.25}, max_hear_distance = 8}
    })
end
