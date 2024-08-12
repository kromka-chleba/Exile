---------------------------------------------------------
--TREES
--

--[[param2
Currently the following meshes are choosable:
  * 0 = a "x" shaped plant (ordinary plant)
  * 1 = a "+" shaped plant (just rotated 45 degrees)
  * 2 = a "*" shaped plant with 3 faces instead of 2
  * 3 = a "#" shaped plant with 4 faces instead of 2
  * 4 = a "#" shaped plant with 4 faces that lean
]]

-- Internationalization
local S = nodes_nature.S

trees = {}

trees.tree_base_tree_growth = 31000
trees.tree_base_leaf_growth = 21000
trees.tree_base_fruit_growth = 19000

local random = math.random
seasons = seasons
minimal = minimal
---------------------------------------------------------
--
-- Leafdecay
--


-- Leafdecay
local function leafdecay_after_destruct(pos, oldnode, def)
	for _, v in pairs(minetest.find_nodes_in_area(vector.subtract(pos, def.radius),
			vector.add(pos, def.radius), def.leaves)) do
		local node = minetest.get_node(v)
		local timer = minetest.get_node_timer(v)
		if node.param2 == 0 and not timer:is_started() then
			timer:start(random(20, 120) / 10)
		end
	end
end

local function leafdecay_on_timer(pos, def)
	if minetest.find_node_near(pos, def.radius, def.trunks) then
		return false
	end

	local node = minetest.get_node(pos)
	local drops = minetest.get_node_drops(node.name)
	for _, item in ipairs(drops) do
		local is_leaf
		for _, v in pairs(def.leaves) do
			if v == item then
				is_leaf = true
			end
		end
		if minetest.get_item_group(item, "leafdecay_drop") ~= 0 or
				not is_leaf then
			minetest.add_item({
				x = pos.x - 0.5 + random(),
				y = pos.y - 0.5 + random(),
				z = pos.z - 0.5 + random(),
			}, item)
		end
	end

	minetest.remove_node(pos)
	minetest.check_for_falling(pos)
end

local function register_leafdecay(def)
	assert(def.leaves)
	assert(def.trunks)
	assert(def.radius)
	for _, v in pairs(def.trunks) do
		minetest.override_item(v, {
			after_destruct = function(pos, oldnode)
				leafdecay_after_destruct(pos, oldnode, def)
			end,
		})
	end
	for _, v in pairs(def.leaves) do
		minetest.override_item(v, {
			on_timer = function(pos)
				leafdecay_on_timer(pos, def)
			end,
		})
	end
end

---------------------------------------------------------
--
--Mark
--used to regrow fruit, leaves, trunks on trees

minetest.register_node(
    "nodes_nature:tree_mark", {
        description = S("Tree Marker"),
	drawtype = "airlike",
        paramtype = "light",
        sunlight_propagates = true,
        walkable = false,
        pointable = false,
        diggable = false,
        buildable_to = true,
        drop = "",
        groups = {not_in_creative_inventory = 1},
        on_construct = function(pos)

        end,
        on_timer = function(pos, elapsed)

	    if seasons.is_winter() then
                 return true
	    end
	    local ntimer = minetest.get_node_timer(pos)
	    local timeout = ntimer:get_timeout()
	    if timeout > trees.tree_base_tree_growth then -- shorten long timers
	       ntimer:set(trees.tree_base_fruit_growth / 2 + random(1,1200), 0)
	    end
            local meta = minetest.get_meta(pos)
            local saved_name = meta:get_string("saved_name")
	    if saved_name == "" then
	       minetest.remove_node(pos) -- Tree mark w/no name from schematic
	       return false
	    end
            local saved_param2 = meta:get_string("saved_param2")
            local leaf_name = meta:get_string("leaf_name")
            local tree_name = meta:get_string("tree_name")
            local positions = minetest.find_nodes_in_area(
                {x = pos.x - 1, y = pos.y - 1, z = pos.z - 1},
                {x = pos.x + 1, y = pos.y + 1, z = pos.z + 1},
                {leaf_name, tree_name})

            if #positions == 0 then
	       local season_nr, season_days = seasons.get_season_and_day()
	       if season_nr == 1 and season_days < 11 then
		  return true -- wait until late spring to give up on regrowth
	       end
	       minetest.remove_node(pos) -- it's dead, Jim!
            elseif climate.get_rain(pos, 15) or
                climate.time_since_rain(elapsed) > 0 then
                --needs rain for growth
	        minetest.set_node(pos, {name = saved_name,
				       param2 = saved_param2})
            else
		     --no rain, so wait, but a shorter time
		     minetest.get_node_timer(pos):set(
			trees.tree_base_fruit_growth / 2 +
			random(1,1200), 0)
                return true
            end
        end
})

-- DEBUG: uncomment to make tree marks visible and pointable
--[[
   minetest.override_item(
      "nodes_nature:tree_mark", {
	 tiles = {"climate_air.png"},
	 post_effect_color = {a = 5, r = 254, g = 254, b = 254},
	 color = {a=0, r=254, g = 254, b = 254},
	 use_texture_alpha = "blend",
	 drawtype = "allfaces",
	 pointable = true
   })
end
]]--

---------------------------------------------------------

local function save_to_tree_mark(pos, oldnode, treename, by_player)
    local param2 = 0
    if by_player then
        param2 = 16
    end
    minetest.set_node(pos, {name = "nodes_nature:tree_mark", param2 = param2})
    local meta = minetest.get_meta(pos)
    -- current backwards compatibility from new devised system
    treename = not treename:match(":") and "nodes_nature:"..treename or treename
    meta:set_string("saved_name", oldnode.name)
    meta:set_string("saved_param2", oldnode.param2)
    meta:set_string("leaf_name", treename.."_leaves")
    meta:set_string("tree_name", treename.."_tree")
end

-- get mark timer data (for determining how you should operate a node timer for treestuff)
-- use timer max table to determine set time
-- use timer min table to determine the lowest point that it should ever go to
-- data (nodedef), datatype (leaf, fruit, defaults to log otherwise)
local function get_mark_timer_data(data, dtype)
  data = type(data) == "table" and minetest.registered_nodes[data.name] or minimal.get_nodedef(data)
  -- returns no data on failure
  if not data then return end
  -- getting timer from base tree timer values
  local dtype_time = dtype == "leaf" and trees.tree_base_leaf_growth or dtype == "fruit" and trees.tree_base_fruit_growth
    or trees.tree_base_tree_growth
  -- setting up "mark_timer" to be used as future logic
  -- prioritize provided nodedef, otherwise create one with provided base dtype logic
  local mark_timer = {min=data.mark_timer_min, max=data.mark_timer_start}
  -- get and set values for max and min
  mark_timer.start = mark_timer.start or type(mark_timer.min) == "number" and mark_timer.min*6 
    or type(mark_timer.min) == "table" and mark_timer.min[2]*4 or dtype_time
  mark_timer.min = mark_timer.min or type(mark_timer.start) == "number" and mark_timer.start/6
    or type(mark_timer.start) == "table" and mark_timer.start[1]/4
  -- set as table (assume 1 as the minimum for random, 2 as the maximum for random)
  -- round up
  mark_timer.start = type(mark_timer.start) == "table" and mark_timer.start or type(mark_timer.start) == "number"
    and {math.ceil(mark_timer.start*0.6),mark_timer.start}
  -- correct minimum
  mark_timer.min = type(mark_timer.min) == "number" and mark_timer.min or math.ceil(mark_timer.start[1]/4)
  -- return
  return mark_timer
end

function trees.register_tree(name,def)
  assert(type(name) == "string","trees.register_tree: got non-string for name: "..tostring(name).." : "..type(name))
  assert(type(def) == "table","trees.register_tree: got non-table for definition: "..tostring(def).." : "..type(def))
  -- check for description and error if unable, as well as other desc argument
  def.description = def.description or def.desc
  def.desc = nil
  assert(type(def.description) == "string","trees.register_tree: base 'description' string needed, got: "..
    tostring(def.description).." : "..type(def.description))
  local desc = def.description -- use for ease of typing + prevent accidental override
  -- add mod_origin
  if not name:match(":") then
    def.mod_origin = def.mod_origin or "nodes_nature"
    name = def.mod_origin..":"..name
  -- create mod_origin (because we use it lol)
  elseif not def.mod_origin then
    local firstp = name:find(":") -- get index of first found ":" - defined as "first point"
    -- grab mod_origin from name and set it
    def.mod_origin = name:sub(1,firstp-1)
  end
  -- used to locate textures
  local texture_base = name:gsub(":","_")
  -- ease of access to defs
  local leaf_def = def.leaf_def or def.leaves_def
  local fruit_def = def.fruit_def
  if leaf_def then
    leaf_def.name = name.."_leaves"
    leaf_def.description = leaf_def.description or S("@1 Leaves",desc)
    leaf_def.groups = leaf_def.groups or {}
    leaf_def.groups.choppy = leaf_def.groups.choppy or 3
    leaf_def.groups.flammable = leaf_def.groups.flammable or 2
    leaf_def.groups.woody_plant = 1
    leaf_def.groups.leafdecay = 1
    leaf_def.groups.leafdecay_drop = 1
    leaf_def.groups.drops_leaves = leaf_def.groups.drops_leaves or 1
    -- if less than 1 then no dropping leaves
    leaf_def.groups.drops_leaves = leaf_def.groups.drops_leaves > 0 and leaf_def.groups.drops_leaves or nil
    -- non-groups stuff
    leaf_def.drawtype = leaf_def.drawtype or "plantlike"
    leaf_def.tiles = leaf_def.tiles or {texture_base.."_leaves.png"}
    leaf_def.paramtype = leaf_def.paramtype or "light"
    leaf_def.paramtype2 = leaf_def.paramtype2 or "meshoptions"
    leaf_def.visual_scale = leaf_def.visual_scale or leaf_def.paramtype2 == "meshoptions" and 1 or nil
    leaf_def.stack_max = leaf_def.stack_max or minimal.stack_max_bulky * 3
    leaf_def.place_param2 = leaf_def.place_param2 or 4
    -- leaves not walkable normally
    if type(leaf_def.walkable) ~= "boolean" then leaf_def.walkable = false end
    -- leaves are usually climbable!
    leaf_def.climbable = type(leaf_def.climbable) ~= "boolean" and true or leaf_def.climbable
    leaf_def.sounds = leaf_def.sounds or nodes_nature.node_sound_leaves_defaults()
    -- functions
    leaf_def.after_place_node = leaf_def.after_place_node or function(pos, placer, itemstack)
      if minimal.player_in_creative(placer) or not minetest.is_player(placer) then
        return
      end
      minimal.switch_node(pos, {name=leaf_def.name, param2 = leaf_def.place_param2 + 128})
    end
    leaf_def.after_destruct = leaf_def.after_destruct or function(pos, node)
      -- wild
      if node.param2 < 128 then
        save_to_tree_mark(pos, node, name, false)
        local season, day = seasons.get_season_and_day()
        -- late winter (hunger)
        if season == 4 then
          local remaining = 20 - day
          minetest.get_node_timer(pos:start(
              random(remaining * 1200, (remaining+5)*1200)
          ))
        -- not winter
        else
          minetest.log("info", "Node at "..
            pos.x.."/"..pos.y.."/"..pos.z..
            " was destroyed outside winter")
          -- CHANGE THESE VALUES !!!
          -- use usual leaf recovery value
          minetest.get_node_timer(pos):start(
            random(trees.tree_base_leaf_growth/2,trees.tree_base_leaf_growth)
          )
        end
      end
    end
    leaf_def.after_dig_node = leaf_def.after_dig_node or function(pos, oldnode, oldmetadata, digger)
      -- wild
      if oldnode.param2 < 128 then
        save_to_tree_mark(pos, oldnode, name, true)
        minetest.get_node_timer(pos):start(
          random(trees.tree_base_leaf_growth/2,trees.tree_base_leaf_growth)
        )
      end
    end
    -- finalizing leaf_def
    minetest.register_node(leaf_def.name,leaf_def)
    def.tree_leaves = leaf_def.name
    def.leaf_def = nil
  end
  if fruit_def then
    fruit_def.name = name.."_fruit"
    fruit_def.description = fruit_def.description or S("@1 Fruit",desc)
    -- fruit groups
    fruit_def.groups = fruit_def.groups or {}
    fruit_def.groups.fruit = 1
    fruit_def.groups.tree_fruit = 1
    fruit_def.groups.flammable = fruit_def.groups.flammable or 2
    fruit_def.groups.dig_immediate = fruit_def.groups.dig_immediate or 3
    fruit_def.groups.leafdecay = fruit_def.groups.leafdecay or 3
    fruit_def.groups.leafdecay_drop = 1
    fruit_def.groups.drops_leaves = fruit_def.groups.drops_leaves or 1
    -- ncrafting_dye_candidate ?
    -- if less than 1 then no dropping leaves
    fruit_def.groups.drops_leaves = fruit_def.groups.drops_leaves > 0 and fruit_def.groups.drops_leaves or nil
    fruit_def.selection_box = fruit_def.selection_box or {
      fixed = {-3 / 16, -7 / 16, -3 / 16,
      3 / 16, 4 / 16, 3 / 16}
    }
    -- very cheap way of making a selection box (just the table itself)
    if not fruit_def.selection_box.fixed and type(fruit_def.selection_box) == "table" then
      fruit_def.selection_box = {fixed = fruit_def.selection_box}
    end
    fruit_def.selection_box.type = fruit_def.selection_box.type or "fixed"
    fruit_def.drawtype = fruit_def.drawtype or "plantlike"
    fruit_def.stack_max = fruit_def.stack_max or minimal.stack_max_medium
    -- imagery
    fruit_def.tiles = fruit_def.tiles or {texture_base.."_fruit.png"}
    fruit_def.inventory_image = fruit_def.inventory_image or texture_base.."_fruit.png"
    fruit_def.wield_image = fruit_def.wield_image or fruit_def.inventory_image
    -- paramtypes
    fruit_def.paramtype = fruit_def.paramtype or "light"
    fruit_def.paramtype2 = fruit_def.paramtype2 or "meshoptions"
    fruit_def.place_param2 = fruit_def.place_param2 or 1 -- 2
    -- default true
    fruit_def.sunlight_propagates = type(fruit_def.sunlight_propagates) ~= "boolean" and true or fruit_def.sunlight_propagates
    if type(fruit_def.walkable) ~= "boolean" then fruit_def.walkable = false end -- default false
    fruit_def.sounds = fruit_def.sounds or nodes_nature.node_sound_defaults()
    -- ncrafting dye
    fruit_def.groups.ncrafting_dye_candidate = fruit_def.dyecandidate == true and 1 or
      type(fruit_def.dyecandidate) == "number" and fruit_def.dyecandidate or nil
    if fruit_def.groups.ncrafting_dye_candidate then
      fruit_def._ncrafting_dye_dcolor = fruit_def._ncrafting_dye_dcolor or fruit_def.dominantcolor or "none"
      fruit_def.dyecandidate = nil
      fruit_def.dominantcolor = nil
    -- remove unnecessary value
    else
      fruit_def._ncrafting_dye_dcolor = nil
    end
    -- functions
    fruit_def.after_place_node = fruit_def.after_place_node or function(pos, placer, itemstack)
      if minimal.player_in_creative(placer) or not minetest.is_player(placer) then
        return
      end
      minimal.switch_node(pos, {name=fruit_def.name, param2 = fruit_def.place_param2 + 128})
    end
    fruit_def.after_destruct = fruit_def.after_destruct or function(pos, node, oldmetadata, digger)
      if node.param2 < 128 then
        save_to_tree_mark(pos, node, name, false)
        local season, day = seasons.get_season_and_day()
        -- late winter (hunger)
        if season == 4 then
          local remaining = 20 - day
          minetest.get_node_timer(pos:start(
              random(remaining * 1200, (remaining+5)*1200)
          ))
        -- not winter
        else
          -- CHANGE THESE VALUES !!!
          -- use usual fruit recovery value
          minetest.get_node_timer(pos):start(
            random(trees.tree_base_fruit_growth/2,trees.tree_base_fruit_growth)
          )
        end
      end
    end
    fruit_def.after_dig_node = fruit_def.after_dig_node or function(pos, oldnode, oldmetadata, digger)
      if oldnode.param2 < 128 then
        save_to_tree_mark(pos, oldnode, name, true)
        minetest.get_node_timer(pos):start(
				   random(trees.tree_base_fruit_growth/2,trees.tree_base_fruit_growth)
        )
      end
    end
    -- finalizing fruit_def
    minetest.register_node(fruit_def.name,fruit_def)
    HEALTH.add_food_hooks(fruit_def.name)
    def.tree_fruit = fruit_def.name
    def.fruit_def = nil
  end
  -- tree trunk
  def.name = name.."_tree"
  def.description = def.log_description or S("@1 Tree",desc)
  def.groups = def.groups or {}
  def.groups.tree = 1
  def.groups.choppy = def.groups.choppy or (def.hardwood and 1) or 2
  def.hardwood = nil
  -- whether or not tree is a hardwood (less than 2 choppy)
  def.groups.hard_tree = def.groups.choppy <= 1 and 1 or nil
  -- flame susceptibility calculation ('hardness' aka choppy multiplied by -2)
  def.groups.flammable = def.groups.flammable or (10 - (def.groups.choppy * -2))
  -- other trunk stuff
  def.stack_max = def.stack_max or minimal.stack_max_bulky
  def.tiles = def.tiles or {
    texture_base.."_tree_top.png",
    texture_base.."_tree_top.png",
    texture_base.."_tree.png"
  }
  def.paramtype = def.paramtype or "light"
  def.paramtype2 = def.paramtype2 or "facedir"
  def.is_ground_content = false
  def.sounds = def.sounds or nodes_nature.node_sound_wood_defaults()
  -- functions
  def.on_place = def.on_place or minetest.rotate_node
  def.after_place_node = def.after_place_node or function(pos, placer, itemstack)
    minetest.set_node(pos, {name=def.name, param2 = 1 + 128})
  end
  def.after_dig_node = def.after_dig_node or function(pos, node)
    -- wild
    if node.param2 < 128 then
      save_to_tree_mark(pos, node, name, true)
      minetest.get_node_timer(pos):start(
        random(trees.tree_base_tree_growth/2,trees.tree_base_tree_growth)
      )
    end
  end
  -- tree log (when a tree trunk is cut)
  local log_def = def.log_def or {}
  log_def.name = name.."_log"
  log_def.description = log_def.description or S("@1 Log",def.description)
  log_def.groups = log_def.groups or {}
  log_def.groups.log = 1
  log_def.groups.choppy = log_def.groups.choppy or def.groups.choppy
  log_def.groups.flammable = log_def.groups.flamamble or def.groups.flammable
  log_def.groups.hard_wood = def.groups.hard_tree and 1 or nil
  log_def.tiles = log_def.tiles or {
    texture_base.."_log_top.png",
    texture_base.."_log_top.png",
    texture_base.."_log.png"
  }
  log_def.stack_max = log_def.stack_max or def.stack_max
  log_def.drawtype = log_def.drawtype or "nodebox"
  log_def.paramtype = log_def.paramtype or "light"
  log_def.paramtype2 = log_def.paramtype2 or "facedir"
  log_def.node_box = log_def.node_box or log_def.drawtype == "nodebox" and {
    type = "fixed",
    fixed = {
      {-0.4375, -0.5, -0.4375, 0.4375, 0.5, 0.4375},
      {-0.375, -0.5, 0.4375, 0.375, 0.5, 0.5},
      {-0.375, -0.5, -0.5, 0.375, 0.5, -0.4375},
      {0.4375, -0.5, -0.375, 0.5, 0.5, 0.375},
      {-0.5, -0.5, -0.375, -0.4375, 0.5, 0.375},
    }
  }
  log_def.is_ground_content = false
  log_def.sounds = log_def.sounds or def.sounds
  -- functions
  log_def.on_place = log_def.on_place or minetest.rotate_node
  -- register log
  minetest.register_node(log_def.name,log_def)

  -- after log definition stuff
  def.drop = log_def.name
  -- register tree trunk
  minetest.register_node(def.name,def)
  -- set leafdecay mechanics
  local tree_leafdecay = {
    trunks = {def.name},
    leaves = {fruit_def and fruit_def.name, leaf_def and leaf_def.name},
    radius = 3,
  }
  -- only register leafdecay if we have either fruit or leaves
  if #tree_leafdecay.leaves > 0 then
    register_leafdecay(tree_leafdecay)
  end
  -- slabs, stairs
  -- only functional difference between hard and soft woods is the crafting
  stairs.register_stair_and_slab(
    name:gsub(def.mod_origin..":",""), -- remove mod_origin from name
    log_def.name, -- used for crafting
    {"chopping_block","axe_mixing"},--..(def.groups.hard_tree and " 2" or "")},
    "false",
    {"chopping_block","axe_mixing"},--..(def.groups.hard_tree and " 2" or "")},
    {choppy = log_def.groups.choppy, flammable = log_def.groups.flammable - 2,
     woodslab = 1},
    log_def.tiles,
    S("@1 Log Stair", def.description),
    S("@1 Log Slab", def.description),
    log_def.stack_max * 2, -- twice log_def stackmax
    log_def.sounds
  )
end
