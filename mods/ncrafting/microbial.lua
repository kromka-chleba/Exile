ncrafting = ncrafting
local S = ncrafting.S

local function microbial_infection(player, pos, nodedef, itemstack, idef)
    -- need player and pos
    if not core.is_player(player) then return end
    if not vector.check(pos) then return end
    -- we can derive these from player and pos
    -- nodedef can be gotten node table, string, or grabbed from pos
    nodedef = type(nodedef) == "table" and nodedef or
      type(nodedef) == "string" and core.registered_nodes[nodedef] or minimal.get_nodedef(pos)
    -- can't ferment or no infection function
    if not (nodedef._ferment_to and nodedef.on_microbial_infection) then return end
    -- figure out itemstack and get its definition
    itemstack = itemstack or player:get_wielded_item()
    idef = idef or itemstack:get_definition()
    -- check if we can infect
    local can_infect = nodedef.on_microbial_infection(player, pos, nodedef, itemstack, idef)
    if not can_infect then return end -- don't do yeast-y things if couldn't infect
    -- allow fermentables to list and play a custom infect sound
    -- otherwise default to own infect sound
    local infect_sound = nodedef.sounds and nodedef.sounds.place_infect or
      idef.sounds and idef.sounds.infect
    if infect_sound then
        minimal.sound_play(pos, infect_sound)
    end
    -- successfully infected, take away item and run on_successful_infection
    if type(idef.on_successful_infection) == "function" then
        idef.on_successful_infection(player, pos, nodedef, itemstack, idef)
    end
    if not minimal.player_in_creative(player) then
        itemstack:take_item()
        return itemstack
    end
end

function ncrafting.register_spreadable_microbe(name, def)
    if type(name) ~= "string" then
        error("ncrafting.register_spreadable_microbe: got type '"..type(name).."' for name.")
    end
    if type(def) ~= "table" then
        error("ncrafting.register_spreadable_microbe: got type '"..type(def).."' for definition.")
    end
    -- now for name stuff
    def.mod_origin = core.get_current_modname()
    name = not name:match(":") and def.mod_origin..":"..name or name
    -- now for definition stuff
    def.stack_max = def.stack_max or minimal.stack_max_medium * 4
    def.inventory_image = def.inventory_image or "tech_yeast_dough_spores.png" -- default to yeast image
    def.description = def.description or name
    -- set up sounds
    def.sounds = def.sounds or {}
    -- permit being false to prevent any sound registration
    def.sounds.infect = def.sounds.infect or def.sounds.infect ~= false and {
        name = "nodes_nature_dig_snappy",
        gain = 0.7
    } or nil
    -- functions
    -- ditto to sound, false to prevent registration
    def.on_successful_infection = def.on_successful_infection or def.on_success_infection ~= false and
      function(player, pos, nodedef, itemstack, idef)
          -- get short description of item and nodedef
          minimal.send_message(player, nil,
            S("@1 added to the @2", itemstack:get_short_description(), ItemStack(nodedef.name):get_short_description()))
      end or nil
    -- the function that'll handle infecting stuff
    def.on_place = def.on_place or def.on_place ~= false and
      function(itemstack, player, pointed_thing)
          -- no possible pos
          if type(pointed_thing) ~= "table" or pointed_thing.type ~= "node" then return end
          return microbial_infection(player, pointed_thing.under, nil, itemstack)
      end or nil
    -- fully register
    core.register_craftitem(name, def)
end