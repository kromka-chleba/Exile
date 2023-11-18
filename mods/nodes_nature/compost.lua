-- Compost

-- Internationalization
local S = nodes_nature.S

-- Compost
-----------------------------------
local compost_decomposing_time = 12000 -- 10 in-game days
local decomposition_interval = 600 -- every 600s
local dry_speed = 600
local wet_speed = 800

local function start_decomposing(pos)
    local meta = minetest.get_meta(pos)
    local decomposition = meta:get_int("decomposition")
    if decomposition < 1 then
        meta:set_int("decomposition", compost_decomposing_time)
    end
    minetest.get_node_timer(pos):start(decomposition_interval)
end

local function catch_up_timer(elapsed, last_updated, decomposition, speed)
    if elapsed and elapsed - last_updated > decomposition_interval then
        return decomposition - elapsed / decomposition_interval * speed
    end
    return decomposition
end

local function save_to_inventory(pos, node, digger)
    if not digger then return false end
    if minetest.is_protected(pos, digger:get_player_name()) then
        return false
    end
    local meta = minetest.get_meta(pos)
    local decomposition = meta:get_int("decomposition")
    local new_stack = ItemStack(node.name)
    local stack_meta = new_stack:get_meta()
    stack_meta:set_int("decomposition", decomposition)
    minetest.remove_node(pos)
    local player_inv = digger:get_inventory()
    if player_inv:room_for_item("main", new_stack) then
        player_inv:add_item("main", new_stack)
    else
        minetest.add_item(pos, new_stack)
    end
end

local function restore_from_inventory(pos, itemstack)
    local meta = minetest.get_meta(pos)
    local stack_meta = itemstack:get_meta()
    local decomposition = stack_meta:get_int("decomposition")
    if decomposition < 1 then
        meta:set_int("decomposition", compost_decomposing_time)
    else
        meta:set_int("decomposition", decomposition)
    end
end

local function decompose_compost(pos, elapsed, dc_name)
  local compdef = minimal.get_nodedef(pos)
  if not compdef or not compdef.groups.undecomposed_compost then
    return false
  end
  local decomposed_name = string.gsub(compdef.name,"_undecomposed","")--"compost"
  if dc_name then
    decomposed_name = dc_name
  end
  local speed = dry_speed
  if type(compdef.groups.wet_sediment) == "number" then
    speed = wet_speed
    decomposed_name = decomposed_name.."_wet"
  end
  if not minimal.get_nodedef(decomposed_name) then
    return false
  end
  local meta = minetest.get_meta(pos)
  local decomposition = meta:get_int("decomposition")
  local last_updated = meta:get_int("last_updated")
  if last_updated == 0 then
      meta:set_int("last_updated", elapsed)
  end
  decomposition = catch_up_timer(elapsed, last_updated, decomposition, speed)
  --minetest.log("decomp: "..decomposition)
  if decomposition < 1 then
      minetest.swap_node(pos, {name = decomposed_name})
      return false
  else
      meta:set_int("decomposition", decomposition - speed)
      return true
  end
end

local base_undecomposed_compost = {
  name = "compost_undecomposed",
  description = S("Undecomposed Compost"),
  groups = {
    fertility = 1,
    falling_node = 1,
  },
  tiles = {"nodes_nature_compost_undecomposed.png"},
  sound = sediment.sounds.dirt,
  stack_max = minimal.stack_max_bulky,
  on_timer = function(pos, elapsed)
    return decompose_compost(pos, elapsed)
  end,
  on_construct = function(pos)
    start_decomposing(pos)
  end,
  on_dig = function(pos, node, digger)
    save_to_inventory(pos, node, digger)
  end,
  after_place_node = function(pos, placer, itemstack, pointed_thing)
    restore_from_inventory(pos, itemstack)
  end
}
local base_compost = {
  name = "compost",
  description = S("Decomposed Compost"),
  groups = {
    crumbly = 3,
    falling_node = 1,
    fertility = 3, -- delicious
    compost = 1,
  },
  tiles = {"nodes_nature_compost.png"},
  sound = sediment.sounds.dirt,
  stack_max = minimal.stack_max_bulky,
  _fertilize_replace_with = "stairs:slab_compost",
  on_use = function(itemstack, user, pointed_thing)
    if pointed_thing.type == "node" then
      return ncrafting.fertilize(pointed_thing.under, user, itemstack)
    end
  end,
  _dig_tip = S("Fertilize soil"),
}
-- so lazy that I'd rather somewhat badly automate it
-- decomposed compost
for i = 1, 6 do
  local reg_compost = table.copy(base_compost)
  local name = reg_compost.name
  if (i == 2 or i == 5) then
    reg_compost.tiles = {sediment.get_wet_texture_name(name)}
    name = name.."_wet"
    reg_compost.description = S("Wet Compost")
    reg_compost.sounds = sediment.sounds.dirt_wet
    reg_compost.groups.wet_compost = 1
  elseif (i == 3 or i == 6) then
    reg_compost.tiles = {sediment.get_wet_salty_texture_name(name)}
    name = name.."_wet_salty"
    reg_compost.description = S("Wet Salty Compost")
    reg_compost.sounds = sediment.sounds.dirt_wet
    reg_compost.groups.wet_compost = 2
  end
  
  -- replace_with and soak soil addition
  if not (i == 1 or i == 4) then
    reg_compost._dig_tip = S("Fertilize and soak soil")
    reg_compost.on_use = function(itemstack, user, pointed_thing)
      if pointed_thing.type == "node" then
        local return_val = {ncrafting.fertilize(pointed_thing.under, user, itemstack)}
        -- only wet the soil if successfully fertilized (will be true or nil for the 3rd parameter)
        if return_val[3] then
          ncrafting.water_soil(itemstack, user, pointed_thing,"","")
        end
        return return_val[1]
      end
    end
    if i == 2 then
      reg_compost._fertilize_replace_with = "stairs:slab_compost_wet"
    elseif i == 3 then
      reg_compost._fertilize_replace_with = "stairs:slab_compost_wet_salty"
    end
  end
  reg_compost.name = name
  if i <= 3 then
    name = "nodes_nature:"..name
    reg_compost.name = name
    minetest.register_node(name,reg_compost)
  else
    --minetest.log("error",reg_compost.texture)
    name = "stairs:slab_"..name
    sediment.register_slab(reg_compost)
    minetest.override_item(name,{
      _dig_tip = reg_compost._dig_tip,
      on_use = reg_compost.on_use,
    })
  end
end
--[[
local compost =
    sediment.new({name = "compost",
                  description = S("Decomposed Compost"),
                  hardness = sediment.hardness.soft,
                  fertility = 1, sound = sediment.sounds.dirt,
                  sound_wet = sediment.sounds.dirt_wet})
 -- add "compost" group
compost.groups.compost = 1
compost.groups_wet.compost = 1

sediment.register_dry(compost)
sediment.register_wet(compost)
sediment.register_wet_salty(compost)
sediment.register_slab(compost)
--]]

local compost_undecomposed =
    sediment.new({name = "compost_undecomposed",
                  description = S("Undecomposed Compost"),
                  hardness = sediment.hardness.soft,
                  fertility = 1, sound = sediment.sounds.dirt,
                  sound_wet = sediment.sounds.dirt_wet})
compost_undecomposed.groups.undecomposed_compost = 1
compost_undecomposed.groups_wet.undecomposed_compost = 1

sediment.register_dry(compost_undecomposed)
sediment.register_wet(compost_undecomposed)
sediment.register_wet_salty(compost_undecomposed)
sediment.register_slab(compost_undecomposed)

local compost_dry_name = sediment.get_dry_name("compost")
local compost_wet_name = sediment.get_wet_name("compost")
local undecomposed_dry_name = sediment.get_dry_name("compost_undecomposed")
local undecomposed_wet_name = sediment.get_wet_name("compost_undecomposed")

minetest.override_item(
    undecomposed_dry_name,
    {
        on_timer = function(pos, elapsed)
            return decompose_compost(pos, elapsed)--false--decompose_compost(pos, compost_dry_name, dry_speed, elapsed)
        end,
        on_construct = function(pos)
            start_decomposing(pos)
        end,
        on_dig = function(pos, node, digger)
            save_to_inventory(pos, node, digger) --undecomposed_dry_name)
        end,
        after_place_node = function(pos, placer, itemstack, pointed_thing)
            restore_from_inventory(pos, itemstack)
        end
})

minetest.override_item(
    "stairs:slab_compost_undecomposed",
    {
        on_timer = function(pos, elapsed)
            return decompose_compost(pos, elapsed)--false--decompose_compost(pos, "stairs:slab_compost", dry_speed, elapsed)
        end,
        on_construct = function(pos)
            start_decomposing(pos)
        end,
        on_dig = function(pos, node, digger)
            save_to_inventory(pos, node, digger) --"stairs:slab_compost_undecomposed")
        end,
        after_place_node = function(pos, placer, itemstack, pointed_thing)
            restore_from_inventory(pos, itemstack)
        end
})

minetest.override_item(
    undecomposed_wet_name,
    {
        on_timer = function(pos, elapsed)
            return decompose_compost(pos, elapsed)--false--decompose_compost(pos, compost_wet_name, wet_speed, elapsed)
        end,
        on_construct = function(pos, wet_speed)
            start_decomposing(pos)
        end,
        on_dig = function(pos, node, digger)
            save_to_inventory(pos, node, digger)
        end,
        after_place_node = function(pos, placer, itemstack, pointed_thing)
            restore_from_inventory(pos, itemstack)
        end
})
--[[
-- fertilize functions
minetest.override_item(
 compost_dry_name,
 {
  _fertilize_replace_with = "stairs:slab_compost",
  on_use = function(itemstack, user, pointed_thing)
    if pointed_thing.type == "node" then
      return ncrafting.fertilize(pointed_thing.under, user, itemstack)
    end
  end,
  _dig_tip = S("Fertilize soil"),
})
minetest.override_item(
  "stairs:slab_compost",
  {
  on_use = function(itemstack, user, pointed_thing)
    if pointed_thing.type == "node" then
      return ncrafting.fertilize(pointed_thing.under, user, itemstack)
    end
  end,
  _dig_tip = S("Fertilize soil"),
})
-- wet fertilize
minetest.override_item(
 compost_wet_name,
 {
  _fertilize_replace_with = "stairs:slab_compost",
  on_use = function(itemstack, user, pointed_thing)
    if pointed_thing.type == "node" then
      local return_val = {ncrafting.fertilize(pointed_thing.under, user, itemstack)}
      -- only wet the soil if successfully fertilized (will be true or nil for the 3rd parameter)
      if return_val[3] then
        ncrafting.water_soil(itemstack, user, pointed_thing,"","")
      end
      return return_val[1]
    end
  end,
  _dig_tip = S("Fertilize and wet soil"),
})
--minetest.override_item(
  --"stairs:slab_compost_wet",
  --{
  --on_use = function(itemstack, user, pointed_thing)
    --if pointed_thing.type == "node" then
      --return ncrafting.fertilize(pointed_thing.under, user, itemstack)
    --end
  --end
--})
--]]

-- backwards compatibility (to slope removal - replaces them with regular compost)
local old_compost_types = {
  "nodes_nature:slope_compost",
  "nodes_nature:slope_inner_compost",
  "nodes_nature:slope_outer_compost",
  "nodes_nature:slope_pike_compost",
}
local old_compost_replacement_table = {
  description = "For old compatibility - ignore",
  groups = {
    not_in_creative_inventory = 1
  },
  _resolve = function(pos)
    minetest.set_node(pos,{name = "nodes_nature:compost"})
  end,
}
for _,old_compost_name in pairs(old_compost_types) do
  for i = 1, 2 do
    local oc_name = old_compost_name -- for easier modification
    local node_table = table.copy(old_compost_replacement_table)
    node_table.on_rightclick = function(pos)
      node_table._resolve(pos)
    end
    node_table.on_punch = function(pos)
      node_table._resolve(pos)
    end
    if i == 2 then
      oc_name = oc_name.."_undecomposed"
      node_table._resolve = function(pos)
        minetest.set_node(pos,{name = "nodes_nature:compost_undecomposed"})
      end
    end
    minetest.register_node(oc_name,node_table)
    minetest.log("beginning: "..oc_name)
    oc_name = oc_name.."_wet"
    for i2 = 1, 2 do
      if i2 == 2 then
        oc_name = oc_name.."_salty"
      end
      minetest.log("ending: "..oc_name)
      minetest.register_node(oc_name,node_table)
    end
  end
end

crafting.register_recipe({
	type = "shovel_agriculture",
	output = "nodes_nature:compost_undecomposed",
	items = {"group:compostable 16"},
	level = 1,
	always_known = true,
})

crafting.register_recipe({
	type = "shovel_agriculture",
	output = "stairs:slab_compost_undecomposed",
	items = {"group:compostable 8"},
	level = 1,
	always_known = true,
})
