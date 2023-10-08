--overrides.lua
--Alters base minetest functions for:
--item_place
--is_protected
--fall damage

local fall_damage_multiplier = 1.5

minetest.override_item("air", { groups = { air = 1,
					   not_in_creative_inventory = 1} })

--A new item_place that allows disabling sneak-rightclick behavior for nodes
--Needed for tech:stick
function minetest.item_place(itemstack, placer, pointed_thing, param2)
        -- Call on_rightclick if the pointed node defines it
        if pointed_thing.type == "node" and minetest.is_player(placer) then
          local ndef = minimal.get_nodedef( pointed_thing.under )
          
          if ndef and (ndef.override_sneak == true or not placer:get_player_control().sneak) then
            local on_click = minimal.on_rightclick(itemstack, placer, pointed_thing)
            if on_click ~= false then
              return on_click or itemstack
            end
          end
        end

        if itemstack:get_definition( ).type == "node" then
                return minetest.item_place_node( itemstack, placer, pointed_thing, param2 )
        end
        return itemstack, nil
end


--Basic protection support
local old_is_protected = minetest.is_protected
function minetest.is_protected(pos, name)
  if minetest.is_player(name) then
    name = name:get_player_name()
  end
   local owner = minetest.get_meta(pos):get_string("owner")
   local bypass = minetest.check_player_privs(name, "protection_bypass")
   if not ( owner == "" or owner == name or
	    bypass ) then
      return true
   end
   return old_is_protected(pos, name)
end

-- Return protection nail if node was nailed
local old_node_dig = minetest.node_dig
function minetest.node_dig(pos, node, digger)
	minimal.protection_on_dig(pos,node,digger)
	return old_node_dig(pos, node, digger)
end

-- Transfer metadata from node to item and back.
minetest.register_on_mods_loaded(function()
	-- Add a preserve_metadata callback to all nodes
	for oName, override in pairs( minetest.registered_nodes ) do
		local old_preserve_metadata = override.preserve_metadata
		minetest.override_item(oName, {
			preserve_metadata = function(pos, oldNode, oldmeta, drops)
				if drops[1] then
					local imeta=drops[1]:get_meta()
					minimal.metadata.preserve_metadata(imeta,oldmeta)
					if type(old_preserve_metadata) == 'function' then
						old_preserve_metadata(pos, oldNode, oldmeta, drops)
					end
				end

			end,
		})
		local old_after_place_node = override.after_place_node
		minetest.override_item(oName, {
			after_place_node = function(pos, placer, itemstack, pointed_thing)
				local imeta = itemstack:get_meta()
				local meta = minetest.get_meta(pos)
				minimal.metadata.after_place_node(imeta,meta)
				if type(old_after_place_node) == 'function' then
					old_after_place_node(pos, placer, itemstack, pointed_thing)
				end
			end,
		})
	end

end)

--Increase fall damage
minetest.register_on_player_hpchange(function(player, hp_change, reason)
	if reason.type == "fall" then
		hp_change = hp_change*fall_damage_multiplier
	end
	return hp_change
end, true)

-- Falling

local SCALE = 0.667
local gravity = tonumber(core.settings:get("movement_gravity")) or 9.81

local facedir_to_euler = {
	{y = 0, x = 0, z = 0},
	{y = -math.pi/2, x = 0, z = 0},
	{y = math.pi, x = 0, z = 0},
	{y = math.pi/2, x = 0, z = 0},
	{y = math.pi/2, x = -math.pi/2, z = math.pi/2},
	{y = math.pi/2, x = math.pi, z = math.pi/2},
	{y = math.pi/2, x = math.pi/2, z = math.pi/2},
	{y = math.pi/2, x = 0, z = math.pi/2},
	{y = -math.pi/2, x = math.pi/2, z = math.pi/2},
	{y = -math.pi/2, x = 0, z = math.pi/2},
	{y = -math.pi/2, x = -math.pi/2, z = math.pi/2},
	{y = -math.pi/2, x = math.pi, z = math.pi/2},
	{y = 0, x = 0, z = math.pi/2},
	{y = 0, x = -math.pi/2, z = math.pi/2},
	{y = 0, x = math.pi, z = math.pi/2},
	{y = 0, x = math.pi/2, z = math.pi/2},
	{y = math.pi, x = math.pi, z = math.pi/2},
	{y = math.pi, x = math.pi/2, z = math.pi/2},
	{y = math.pi, x = 0, z = math.pi/2},
	{y = math.pi, x = -math.pi/2, z = math.pi/2},
	{y = math.pi, x = math.pi, z = 0},
	{y = -math.pi/2, x = math.pi, z = 0},
	{y = 0, x = math.pi, z = 0},
	{y = math.pi/2, x = math.pi, z = 0}
}

minetest.register_entity(
    ":__builtin:falling_node", {
        initial_properties = {
            visual = "item",
            visual_size = vector.new(SCALE, SCALE, SCALE),
            textures = {},
            physical = true,
            is_visible = false,
            collide_with_objects = true,
            collisionbox = {-0.5, -0.5, -0.5, 0.5, 0.5, 0.5},
        },

        node = {},
        meta = {},
        floats = false,

        set_node = function(self, node, meta)
            node.param2 = node.param2 or 0
            self.node = node
            meta = meta or {}
            if type(meta.to_table) == "function" then
                meta = meta:to_table()
            end
            for _, list in pairs(meta.inventory or {}) do
                for i, stack in pairs(list) do
                    if type(stack) == "userdata" then
                        list[i] = stack:to_string()
                    end
                end
            end
            local def = minetest.registered_nodes[node.name]
            if not def then
                -- Don't allow unknown nodes to fall
                minetest.log("info",
                             "Unknown falling node removed at "..
                             minetest.pos_to_string(self.object:get_pos()))
                self.object:remove()
                return
            end
            self.meta = meta

            -- Cache whether we're supposed to float on water
            self.floats = minetest.get_item_group(node.name, "float") ~= 0

            -- Save liquidtype for falling water
            self.liquidtype = def.liquidtype

            -- Set entity visuals
            if def.drawtype == "torchlike" or def.drawtype == "signlike" then
                local textures
                if def.tiles and def.tiles[1] then
                    local tile = def.tiles[1]
                    if type(tile) == "table" then
                        tile = tile.name
                    end
                    if def.drawtype == "torchlike" then
                        textures = { "("..tile..")^[transformFX", tile }
                    else
                        textures = { tile, "("..tile..")^[transformFX" }
                    end
                end
                local vsize
                if def.visual_scale then
                    local s = def.visual_scale
                    vsize = vector.new(s, s, s)
                end
                self.object:set_properties({
                        is_visible = true,
                        visual = "upright_sprite",
                        visual_size = vsize,
                        textures = textures,
                        glow = def.light_source,
                })
            elseif def.drawtype ~= "airlike" then
                local itemstring = node.name
                if minetest.is_colored_paramtype(def.paramtype2) then
                    itemstring = minetest.itemstring_with_palette(itemstring, node.param2)
                end
                -- FIXME: solution needed for paramtype2 == "leveled"
                -- Calculate size of falling node
                local s = {}
                s.x = (def.visual_scale or 1) * SCALE
                s.y = s.x
                s.z = s.x
                -- Compensate for wield_scale
                if def.wield_scale then
                    s.x = s.x / def.wield_scale.x
                    s.y = s.y / def.wield_scale.y
                    s.z = s.z / def.wield_scale.z
                end
                self.object:set_properties({
                        is_visible = true,
                        wield_item = itemstring,
                        visual_size = s,
                        glow = def.light_source,
                })
            end

            -- Set collision box (certain nodeboxes only for now)
            local nb_types = {fixed=true, leveled=true, connected=true}
            if def.drawtype == "nodebox" and def.node_box and
                nb_types[def.node_box.type] and def.node_box.fixed then
                local box = table.copy(def.node_box.fixed)
                if type(box[1]) == "table" then
                    box = #box == 1 and box[1] or nil -- We can only use a single box
                end
                if box then
                    if def.paramtype2 == "leveled" and (self.node.level or 0) > 0 then
                        box[5] = -0.5 + self.node.level / 64
                    end
                    self.object:set_properties({
                            collisionbox = box
                    })
                end
            end

            -- Rotate entity
            if def.drawtype == "torchlike" then
                self.object:set_yaw(math.pi*0.25)
            elseif ((node.param2 ~= 0 or def.drawtype == "nodebox" or def.drawtype == "mesh")
                and (def.wield_image == "" or def.wield_image == nil))
                or def.drawtype == "signlike"
                or def.drawtype == "mesh"
                or def.drawtype == "normal"
                or def.drawtype == "nodebox" then
                if (def.paramtype2 == "facedir" or def.paramtype2 == "colorfacedir") then
                    local fdir = node.param2 % 32 % 24
                    -- Get rotation from a precalculated lookup table
                    local euler = facedir_to_euler[fdir + 1]
                    if euler then
                        self.object:set_rotation(euler)
                    end
                elseif (def.paramtype2 == "4dir" or def.paramtype2 == "color4dir") then
                    local fdir = node.param2 % 4
                    -- Get rotation from a precalculated lookup table
                    local euler = facedir_to_euler[fdir + 1]
                    if euler then
                        self.object:set_rotation(euler)
                    end
                elseif (def.drawtype ~= "plantlike" and def.drawtype ~= "plantlike_rooted" and
                        (def.paramtype2 == "wallmounted" or def.paramtype2 == "colorwallmounted" or def.drawtype == "signlike")) then
                    local rot = node.param2 % 8
                    if (def.drawtype == "signlike" and def.paramtype2 ~= "wallmounted" and def.paramtype2 ~= "colorwallmounted") then
                        -- Change rotation to "floor" by default for non-wallmounted paramtype2
                        rot = 1
                    end
                    local pitch, yaw, roll = 0, 0, 0
                    if def.drawtype == "nodebox" or def.drawtype == "mesh" then
                        if rot == 0 then
                            pitch, yaw = math.pi/2, 0
                        elseif rot == 1 then
                            pitch, yaw = -math.pi/2, math.pi
                        elseif rot == 2 then
                            pitch, yaw = 0, math.pi/2
                        elseif rot == 3 then
                            pitch, yaw = 0, -math.pi/2
                        elseif rot == 4 then
                            pitch, yaw = 0, math.pi
                        end
                    else
                        if rot == 1 then
                            pitch, yaw = math.pi, math.pi
                        elseif rot == 2 then
                            pitch, yaw = math.pi/2, math.pi/2
                        elseif rot == 3 then
                            pitch, yaw = math.pi/2, -math.pi/2
                        elseif rot == 4 then
                            pitch, yaw = math.pi/2, math.pi
                        elseif rot == 5 then
                            pitch, yaw = math.pi/2, 0
                        end
                    end
                    if def.drawtype == "signlike" then
                        pitch = pitch - math.pi/2
                        if rot == 0 then
                            yaw = yaw + math.pi/2
                        elseif rot == 1 then
                            yaw = yaw - math.pi/2
                        end
                    elseif def.drawtype == "mesh" or def.drawtype == "normal" or def.drawtype == "nodebox" then
                        if rot >= 0 and rot <= 1 then
                            roll = roll + math.pi
                        else
                            yaw = yaw + math.pi
                        end
                    end
                    self.object:set_rotation({x=pitch, y=yaw, z=roll})
                elseif (def.drawtype == "mesh" and def.paramtype2 == "degrotate") then
                    local p2 = (node.param2 - (def.place_param2 or 0)) % 240
                    local yaw = (p2 / 240) * (math.pi * 2)
                    self.object:set_yaw(yaw)
                elseif (def.drawtype == "mesh" and def.paramtype2 == "colordegrotate") then
                    local p2 = (node.param2 % 32 - (def.place_param2 or 0) % 32) % 24
                    local yaw = (p2 / 24) * (math.pi * 2)
                    self.object:set_yaw(yaw)
                end
            end
        end,

        get_staticdata = function(self)
            local ds = {
                node = self.node,
                meta = self.meta,
            }
            return minetest.serialize(ds)
        end,

        on_activate = function(self, staticdata)
            self.object:set_armor_groups({immortal = 1})
            self.object:set_acceleration(vector.new(0, -gravity, 0))

            local ds = minetest.deserialize(staticdata)
            if ds and ds.node then
                self:set_node(ds.node, ds.meta)
            elseif ds then
                self:set_node(ds)
            elseif staticdata ~= "" then
                self:set_node({name = staticdata})
            end
        end,

        try_place = function(self, bcp, bcn)
            local bcd = minetest.registered_nodes[bcn.name]
            -- Add levels if dropped on same leveled node
            if bcd and bcd.paramtype2 == "leveled" and
                bcn.name == self.node.name then
                local addlevel = self.node.level
                if (addlevel or 0) <= 0 then
                    addlevel = bcd.leveled
                end
                if minetest.add_node_level(bcp, addlevel) < addlevel then
                    return true
                elseif bcd.buildable_to then
                    -- Node level has already reached max, don't place anything
                    return true
                end
            end

            -- Decide if we're replacing the node or placing on top
            local np = vector.copy(bcp)
            if bcd and bcd.buildable_to and
                ((not self.floats or bcd.liquidtype == "none") or
                    (self.floats and self.liquidtype ~= "none" and bcd.liquidtype ~= "source")) then
                minetest.remove_node(bcp)
            else
                np.y = np.y + 1
            end

            -- Check what's here
            local n2 = minetest.get_node(np)
            local nd = minetest.registered_nodes[n2.name]
            -- If it's not air or liquid, remove node and replace it with
            -- it's drops
            if n2.name ~= "air" and (not nd or nd.liquidtype ~= "source") then
                if nd and nd.buildable_to == false then
                    nd.on_dig(np, n2, nil)
                    -- If it's still there, it might be protected
                    if minetest.get_node(np).name == n2.name then
                        return false
                    end
                else
                    minetest.remove_node(np)
                end
            end

            -- Create node
            local def = minetest.registered_nodes[self.node.name]
            if def then
                minetest.add_node(np, self.node)
                if self.meta then
                    minetest.get_meta(np):from_table(self.meta)
                end
                if def.sounds and def.sounds.place then
                    minetest.sound_play(def.sounds.place, {pos = np}, true)
                end
            end
            minetest.check_for_falling(np)
            return true
        end,

        on_step = function(self, dtime, moveresult)
            -- Fallback code since collision detection can't tell us
            -- about liquids (which do not collide)
            if self.floats then
                local pos = self.object:get_pos()

                local bcp = pos:offset(0, -0.7, 0):round()
                local bcn = minetest.get_node(bcp)

                local bcd = minetest.registered_nodes[bcn.name]
                if bcd and bcd.liquidtype ~= "none" then
                    if self:try_place(bcp, bcn) then
                        self.object:remove()
                        return
                    end
                end
            end

            assert(moveresult)
            if not moveresult.collides then
                return -- Nothing to do :)
            end

            local bcp, bcn
            local player_collision
            if moveresult.touching_ground then
                for _, info in ipairs(moveresult.collisions) do
                    if info.type == "object" then
                        if info.axis == "y" and info.object:is_player() then
                            player_collision = info
                        end
                    elseif info.axis == "y" then
                        bcp = info.node_pos
                        bcn = minetest.get_node(bcp)
                        break
                    end
                end
            end

            if not bcp then
                -- We're colliding with something, but not the ground. Irrelevant to us.
                if player_collision then
                    -- Continue falling through players by moving a little into
                    -- their collision box
                    -- TODO: this hack could be avoided in the future if objects
                    --       could choose who to collide with
                    local vel = self.object:get_velocity()
                    self.object:set_velocity(vector.new(
                                                 vel.x,
                                                 player_collision.old_velocity.y,
                                                 vel.z
                    ))
                    self.object:set_pos(self.object:get_pos():offset(0, -0.5, 0))
                end
                return
            elseif bcn.name == "ignore" then
                -- Delete on contact with ignore at world edges
                self.object:remove()
                return
            end

            local failure = false

            local pos = self.object:get_pos()
            local distance = vector.apply(vector.subtract(pos, bcp), math.abs)
            if distance.x >= 1 or distance.z >= 1 then
                -- We're colliding with some part of a node that's sticking out
                -- Since we don't want to visually teleport, drop as item
                failure = true
            elseif distance.y >= 2 then
                -- Doors consist of a hidden top node and a bottom node that is
                -- the actual door. Despite the top node being solid, the moveresult
                -- almost always indicates collision with the bottom node.
                -- Compensate for this by checking the top node
                bcp.y = bcp.y + 1
                bcn = minetest.get_node(bcp)
                local def = minetest.registered_nodes[bcn.name]
                if not (def and def.walkable) then
                    failure = true -- This is unexpected, fail
                end
            end

            -- Try to actually place ourselves
            if not failure then
                failure = not self:try_place(bcp, bcn)
            end

            if failure then
                local drops = minetest.get_node_drops(self.node, "")
                for _, item in pairs(drops) do
                    minetest.add_item(pos, item)
                end
            end
            self.object:remove()
        end
})

local function convert_to_falling_node(pos, node)
    local obj = core.add_entity(pos, "__builtin:falling_node")
    if not obj then
        return false
    end
    -- remember node level, the entities' set_node() uses this
    node.level = core.get_node_level(pos)
    local meta = core.get_meta(pos)
    local metatable = meta and meta:to_table() or {}

    local def = core.registered_nodes[node.name]
    if def and def.sounds and def.sounds.fall then
        core.sound_play(def.sounds.fall, {pos = pos}, true)
    end

    obj:get_luaentity():set_node(node, metatable)
    core.remove_node(pos)
    return true, obj
end

local builtin_shared = {}

builtin_shared.check_attached_node = function(p, n, group_rating)
    local def = core.registered_nodes[n.name]
    local d = vector.zero()
    if group_rating == 3 then
        -- always attach to floor
        d.y = -1
    elseif group_rating == 4 then
        -- always attach to ceiling
        d.y = 1
    elseif group_rating == 2 then
        -- attach to facedir or 4dir direction
        if (def.paramtype2 == "facedir" or
            def.paramtype2 == "colorfacedir") then
            -- Attach to whatever facedir is "mounted to".
            -- For facedir, this is where tile no. 5 point at.

            -- The fallback vector here is in case 'facedir to dir' is nil due
            -- to voxelmanip placing a wallmounted node without resetting a
            -- pre-existing param2 value that is out-of-range for facedir.
            -- The fallback vector corresponds to param2 = 0.
            d = core.facedir_to_dir(n.param2) or vector.new(0, 0, 1)
        elseif (def.paramtype2 == "4dir" or
                def.paramtype2 == "color4dir") then
            -- Similar to facedir handling
            d = core.fourdir_to_dir(n.param2) or vector.new(0, 0, 1)
        end
    elseif def.paramtype2 == "wallmounted" or
        def.paramtype2 == "colorwallmounted" then
        -- Attach to whatever this node is "mounted to".
        -- This where tile no. 2 points at.

        -- The fallback vector here is used for the same reason as
        -- for facedir nodes.
        d = core.wallmounted_to_dir(n.param2) or vector.new(0, 1, 0)
    else
        d.y = -1
    end
    local p2 = vector.add(p, d)
    local nn = core.get_node(p2).name
    local def2 = core.registered_nodes[nn]
    if def2 and not def2.walkable then
        return false
    end
    return true
end

local function drop_attached_node(p)
    local n = core.get_node(p)
    local drops = core.get_node_drops(n, "")
    local def = core.registered_items[n.name]
    if def and def.preserve_metadata then
        local oldmeta = core.get_meta(p):to_table().fields
        -- Copy pos and node because the callback can modify them.
        local pos_copy = vector.copy(p)
        local node_copy = {name=n.name, param1=n.param1, param2=n.param2}
        local drop_stacks = {}
        for k, v in pairs(drops) do
            drop_stacks[k] = ItemStack(v)
        end
        drops = drop_stacks
        def.preserve_metadata(pos_copy, node_copy, oldmeta, drops)
    end
    if def and def.sounds and def.sounds.fall then
        core.sound_play(def.sounds.fall, {pos = p}, true)
    end
    core.remove_node(p)
    for _, item in pairs(drops) do
        local pos = {
            x = p.x + math.random()/2 - 0.25,
            y = p.y + math.random()/2 - 0.25,
            z = p.z + math.random()/2 - 0.25,
        }
        core.add_item(pos, item)
    end
end

function minetest.check_single_for_falling(p)
    local n = minetest.get_node(p)
    if minetest.get_item_group(n.name, "falling_node") ~= 0 then
        local p_bottom = vector.offset(p, 0, -1, 0)
        -- Only spawn falling node if node below is loaded
        local n_bottom = minetest.get_node_or_nil(p_bottom)
        local d_bottom = n_bottom and minetest.registered_nodes[n_bottom.name]
        if d_bottom then
            local same = n.name == n_bottom.name
            -- Let leveled nodes fall if it can merge with the bottom node
            if same and d_bottom.paramtype2 == "leveled" and
                minetest.get_node_level(p_bottom) <
                minetest.get_node_max_level(p_bottom) then
                local success, _ = convert_to_falling_node(p, n)
                return success
            end
            local d_falling = minetest.registered_nodes[n.name]
            -- Otherwise only if the bottom node is considered "fall through"
            if not same and
                (not d_bottom.walkable or d_bottom.buildable_to) and
                ((minetest.get_item_group(n.name, "float") == 0 or
                  d_bottom.liquidtype == "none") or
                    (minetest.get_item_group(n.name, "float") > 0 and
                     d_falling.liquidtype == "source" and
                     d_bottom.liquidtype ~= "source")) then
                local success, _ = convert_to_falling_node(p, n)
                return success
            end
        end
    end

    local an = minetest.get_item_group(n.name, "attached_node")
    if an ~= 0 then
        if not builtin_shared.check_attached_node(p, n, an) then
            drop_attached_node(p)
            return true
        end
    end

    return false
end
