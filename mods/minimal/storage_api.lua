storage = {}

local modname = "minimal/storage_api.lua"

local S = minimal.S

-- functionality for determining if a player is looking in storage
local storage_watched = {}
local function get_watchers(pos, create)
  pos = type(pos) == "string" and pos or type(pos) == "table" and minetest.pos_to_string(pos)
  -- create a new watcher table if it doesn't exist
  if create then
    storage_watched[pos] = storage_watched[pos] or {}
  end
  return storage_watched[pos] or {} -- send watcher table or create an empty one
end
local function add_watcher(pos, pname)
  local wt = get_watchers(pos, true) -- watch_table
  pname = type(pname) == "string" and pname or (type(pname) == "userdata" or type(pname) == "table") and pname.get_player_name and pname:get_player_name()
  -- iterate over table for nil indexes because Lua is dysfunctional when it comes to counting
  for wi=1,(#wt + 1) do
    if wt[wi] == pname then return false end
    if wt[wi] == nil then
      wt[wi] = pname
      break
    end
  end
end
local function remove_watcher(pos, pname)
  local wt = get_watchers(pos) -- watch_table
  if #wt < 1 then return end -- no watch table
  pname = type(pname) == "string" and pname or (type(pname) == "userdata" or type(pname) == "table") and pname.get_player_name and pname:get_player_name()
  -- iterate over table to find name and remove
  for wi=1,#wt do
    if wt[wi] == pname then
      wt[wi] = nil
      -- delete table if empty
      if #wt < 1 then storage_watched[pos] = nil end
      return true
    end
  end
end

function storage.get_storage_formspec(pos, w, h, meta)
	local creator = meta:get_string('creator')
	local label = minimal.sanitize_string(meta:get_string('label'))
	minimal.infotext_merge(pos, S('Label')..': '..label, meta)
	local formspec_size_h = 3.85 + h
	local main_offset = 0.25 + h
	local trash_offset = 0.45 + h + 2
	local label_offset = trash_offset + .35
	local creator_offset_x =  (3*(30-string.len(creator))/30/2) + 5
	local craftedby_offset_x = 6.05 -- 3*(30-string.len('crafted by'))/30/2 + 5

	local formspec = {
		"size[8,"..formspec_size_h.."]",
		"list[current_name;main;0,0;"..w..","..h.."]",
		"list[current_player;main;0,"..main_offset..";8,2]",
		"listring[current_name;main]",
		"listring[current_player;main]",
		"list[detached:creative_trash;main;0,"..trash_offset..";1,1;]",
		"image[0.05,"..(trash_offset+.10)..
		   ";0.8,0.8;creative_trash_icon.png]",
		"field[1.5,"..label_offset..";4,1;label;"..
		   S("Label")..":;"..label.."]",
		"field_close_on_enter[label;false]",
		"button[5,"..label_offset..";1,0.25;labelset;"..S("Set").."]",
		--"label["..craftedby_offset_x..","..trash_offset..";Crafted by:]",
		--"label["..creator_offset_x..","..(trash_offset+.35)..";"..creator.."]",
	}
  if (creator and creator ~= '') then
     formspec[#formspec + 1] = "label["..craftedby_offset_x..","..trash_offset..
	";"..S("Crafted by")..":]"
    formspec[#formspec + 1] = "label["..creator_offset_x..","..(trash_offset+.35)..";"..creator.."]"
  end
	return table.concat(formspec, "")
end


local function can_interact(pos, name, meta)
	if minetest.is_protected(pos, name, meta) then
    -- you are NOT the owner!
    return false
  end
  -- returns true if the node isn't protected from the player lol
  return true
end

function storage.can_dig(pos,player,can_grab)
  local inv_empty = true
  local meta = minetest.get_meta(pos)

  if not can_grab then
    local inv = meta:get_inventory()
    inv_empty = inv:is_empty("main")
  end

  return can_interact(pos, player, meta) and inv_empty
end

function storage.get_inventory(pos)
  if (type(pos.x) == "number" and type(pos.y) == "number" and type(pos.z) == "number") then
    return minetest.get_meta(pos):get_inventory()
  elseif (type(pos["get_inventory"]) == "function") then
    -- allow meta as an argument
    return pos:get_inventory()
  end
end

function storage.on_construct(pos, width, height)
	local meta = minetest.get_meta(pos)

	local form = storage.get_storage_formspec(pos, width, height, meta)
	meta:set_string("formspec", form)

	local inv = storage.get_inventory(meta)
	inv:set_size("main", width*height)
end

function storage.on_receive_fields(pos, formname, fields, sender, width, height)
  local label = fields.label
  -- only get meta if label was modified and sender is a player
  local meta = label and minetest.is_player(sender) and minetest.get_meta(pos) or nil
  -- thus we can use meta to check if we can set up the new label
  if meta and can_interact(pos,sender, meta) then
    local meta = minetest.get_meta(pos)
    local cleanlabel = minimal.sanitize_string(label)
    meta:set_string('label', cleanlabel)
    minimal.infotext_merge(pos,S('Label')..': '..cleanlabel, meta)
    storage.on_construct(pos, width, height)
  end
  -- sounds
  remove_watcher(pos, sender)
  if #get_watchers(pos) < 1 and not minetest.is_protected(pos, sender, meta) then
    local sounds = minimal.get_nodedef(pos)
    sounds = sounds.sounds or {}
    local sound = sounds.storage_close and table.copy(sounds.storage_close)
    if sound then
      sound.pos = pos
      minetest.sound_play(sound.name,sound)
    end
  end
end

-- basic dump_inventory function
-- optional meta argument
function storage.dump_inventory(pos, meta)
  assert(type(pos) == "table","mods/"..modname.."dump_inventory: Invalid pos provided!")
  assert( (type(pos.x) == "number" and type(pos.y) == "number" and type(pos.z) == "number"),
    "mods/"..modname.."dump_inventory: Invalid pos provided!")

  -- verify if the dumped inventory belongs to a storage container
  local stor_node = minetest.get_node(pos)
  if not minimal.in_group(stor_node,"storage") then return end

  meta = type(meta) == "userdata" and meta or minetest.get_meta(pos)
  -- don't attempt to empty out an empty inventory
  local inv = meta:get_inventory()
  if inv:is_empty("main") then
    return
  end

  -- empty it out!
  local dump_pos = {x = pos.x, y = pos.y + 1, z = pos.z}
  for _,itemstack in pairs(inv:get_list("main")) do
    itemstack = inv:remove_item("main",itemstack)

    -- drop items
    minetest.item_drop(itemstack, nil, dump_pos)
  end
end

-- to_burnt
-- optional meta argument, otherwise gets meta
local function to_burnt(pos, meta)
  local stor_node = minetest.get_node(pos)
  if not minimal.in_group(stor_node,"storage") then return end -- not storage, why did this get ran?
  stor_node = minetest.registered_nodes[stor_node.name]
  local burn_to = stor_node.burn_to
  -- can't be burned lol
  if type(burn_to) ~= "string" then
    return
  end
  -- if burn_to empty, assume air, otherwise use burn_to
  burn_to = burn_to == "" and "air" or burn_to
  burn_to = minetest.registered_nodes[burn_to]
  -- could not find burn_to node
  if not burn_to then return end

  meta = type(meta) == "userdata" and meta or minetest.get_meta(pos)
  if type(stor_node.metadata_inventory_dump) == "function" then
    -- run on_dump code
    stor_node.metadata_inventory(pos, meta)
  end

  -- if burn_to node is not storage then don't try to add storage aspects to it!
  if not minimal.in_group(burn_to,"storage") then return end

  -- creating burn_to storage variant
  -- get formspec width and height
  local width = stor_node.formspec_width or 8
  local height = stor_node.formspec_height or 4

  -- set formspec_width and formspec_height as meta_int
  meta:set_int("formspec_width",width)
  meta:set_int("formspec_height",height)

  -- does the inventory saving for me :D \/ (as well as saves owner, label, and the width and height metadata)
  minimal.switch_node(pos,{name = burn_to.name})
end

function storage.register_storage(name,def)
  assert(type(name) == "string","mods/"..modname..".register_storage: No string provided for name!")
  assert(type(def) == "table","mods/"..modname..".register_storage: No table provided for definition!")
  
  def.groups = def.groups or {}
  def.groups.storage = 1
  def.stack_max = def.stack_max or minimal.stack_max_bulky
  def.drawtype = def.drawtype or "nodebox"
  def.node_box = def.node_box or def.drawtype == "nodebox" and {
    -- basic storage container shape
    type = "fixed",
    fixed = {
      {-0.375, -0.5, -0.375, 0.375, -0.375, 0.375},
      {-0.375, 0.375, -0.375, 0.375, 0.5, 0.375},
      {-0.4375, -0.375, -0.4375, 0.4375, -0.25, 0.4375},
      {-0.4375, 0.25, -0.4375, 0.4375, 0.375, 0.4375},
      {-0.5, -0.25, -0.5, 0.5, 0.25, 0.5},
    }
  }
  def.paramtype = "light"
  -- custom values
  -- formspec for storage inventory
  def.formspec_width = def.formspec_width or 8
  def.formspec_height = def.formspec_height or 4
  -- integers only
  def.formspec_width = math.ceil(def.formspec_width)
  def.formspec_height = math.ceil(def.formspec_height)
  -- automatic protection
  def.protected = def.protected == true and true or false
  -- can be dug if there's itemstacks inside (default false)
  def.can_dig_when_inventory = def.can_dig_when_inventory == true and true or false
  -- legacy usage for flammable setting
  def.groups.flammable = def.groups.flammable or def.burnable and 1
  def.burnable = nil
  -- what to burn to when set ablaze, sets a default if flammable
  def.burn_to = def.burn_to or def.groups.flammable and "minimal:burnt_storage_pile" or nil
  -- functions
  def.allow_metadata_inventory_move = def.allow_metadata_inventory_move or
  function(pos, from_list, from_index, to_list, to_index, count, player)
    if can_interact(pos, player) then
      return count
    end
    return 0
  end

  def.allow_metadata_inventory_put = def.allow_metadata_inventory_put or
  function(pos, listname, index, stack, player)
    if can_interact(pos, player)
    and minetest.get_item_group(stack:get_name(),"backpack") == 0 then
      return stack:get_count()
    elseif minetest.get_item_group(stack:get_name(),"backpack") > 0 then
      local imeta = stack:get_meta()
      local inv_list = imeta:get_string("inv_main") -- custom inventory metastring for bags
      if inv_list == "" then
        inv_list = {}
      else
        -- got an actual serialized table, deserialize
        inv_list = minetest.deserialize(inv_list)
        for invdex,content in pairs(inv_list) do
          if content == "" then
            -- remove index manually, table.remove did not work lol
            inv_list[invdex] = nil
          end
        end
      end
      -- allow putting empty bags in storage
      if #inv_list <= 0 then
        return stack:get_count()
      end
    end
    return 0
  end

  def.allow_metadata_inventory_take = def.allow_metadata_inventory_take or
  function(pos, listname, index, stack, player)
    if can_interact(pos, player) then
      return stack:get_count()
    end
    return 0
  end

  def.on_blast = def.on_blast or function(pos) end
  def.metadata_inventory_dump = def.metadata_inventory_dump or function(pos)
    storage.dump_inventory(pos)
  end
  -- declaring locals for formspec details (makes it easier to set up functions)
  local width = def.formspec_width
  local height = def.formspec_height
  -- basic functions
  def.can_dig = def.can_dig or function(pos, player)
    return storage.can_dig(pos, player, def.can_dig_when_inventory)
  end

  def.on_receive_fields = def.on_receive_fields or function(pos, formname, fields, sender)
    storage.on_receive_fields(pos, formname, fields, sender, width, height)
  end

  def.on_construct = def.on_construct or function(pos)
    storage.on_construct(pos, width, height)
  end

  def.after_place_node = def.after_place_node or function(pos, placer, itemstack, pointed_thing)
    --Update formspec and infotext
    if (minetest.is_player(placer) and def.protected == true) then
      local p_name = placer:get_player_name() or ""
      minetest.get_meta(pos):set_string("owner", p_name)
    end
    storage.on_construct(pos, width, height)
  end
  
  def.on_rightclick = def.on_rightclick or function(pos, node, clicker, itemstack, pointed_thing)
    if minetest.is_protected(pos, clicker) then return end -- no touchy touchy
    -- sounds
    if #get_watchers(pos) < 1 then
      local sounds = minimal.get_nodedef(pos)
      sounds = sounds.sounds or {}
      local sound = sounds.storage_open and table.copy(sounds.storage_open)
      if sound then
        sound.pos = pos
        minetest.sound_play(sound.name,sound)
      end
    end
    add_watcher(pos, clicker)
  end

  def.on_burn = def.on_burn or def.burn_to and function(pos)
    to_burnt(pos)
  end

  -- register the node
  minetest.register_node(name,def)
end

-- burnt storage pile code
local burnt_storage = {
  description = S("Burnt Storage Pile"),
  tiles = {"minimal_burnt_pile.png"},

  node_box = {
    type = "fixed",
    fixed = {
      {-0.45 , -0.5, -0.45,   0.45, -0.3, 0.45}, -- first layer
      {-0.35 , -0.3, -0.35,   0.35, -0.2, 0.35},
      {-0.2 , -0.2, -0.2,   0.2, -0.15, 0.2},
    },
  },

  groups = {burnt = 1, dig_immediate = 3, no_dump = 1},

  on_construct = function(pos)
    local meta = minetest.get_meta(pos)
    local width = meta:get_int("formspec_width")
    local height = meta:get_int("formspec_height")
    if (width ~= 0 and height ~= 0) then
      storage.on_construct(pos,width,height)
    else
      storage.on_construct(pos,8,4)
    end
  end,
  allow_metadata_inventory_put = function(pos, listname, index, stack, player)
    -- do not allow players to use the burnt storage
    return 0
  end,
  -- make after_place_node and on_receive_fields nil
  after_place_node = function()
  end,
  on_receive_fields = function()
  end,
}

storage.register_storage("minimal:burnt_storage_pile",burnt_storage)
