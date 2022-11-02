-------------------------------------------------------------------
--From mcl_mapgen_core api (how much is actually needed is unknown)
local registered_generators = {}

local lvm, nodes, param2 = 0, 0, 0
local lvm_buffer = {}

local logging = minetest.settings:get_bool("mcl_logging_mapgen",false)

local function roundN(n, d)
	if type(n) ~= "number" then return n end
    local m = 10^d
    return math.floor(n * m + 0.5) / m
end

minetest.register_on_generated(function(minp, maxp, blockseed)
	local t1 = os.clock()
	local p1, p2 = {x=minp.x, y=minp.y, z=minp.z}, {x=maxp.x, y=maxp.y, z=maxp.z}
	if lvm > 0 then
		local lvm_used, shadow, deco_used = false, false, false
		local lb2 = {} -- param2
		local vm, emin, emax = minetest.get_mapgen_object("voxelmanip")
		local e1, e2 = {x=emin.x, y=emin.y, z=emin.z}, {x=emax.x, y=emax.y, z=emax.z}
		local data2
		local data = vm:get_data(lvm_buffer)
		if param2 > 0 then
			data2 = vm:get_param2_data(lb2)
		end
		local area = VoxelArea:new({MinEdge=e1, MaxEdge=e2})

		for _, rec in ipairs(registered_generators) do
			if rec.vf then
				local lvm_used0, shadow0, deco = rec.vf(vm, data, data2, e1, e2, area, p1, p2, blockseed)
				if lvm_used0 then
					lvm_used = true
				end
				if shadow0 then
					shadow = true
				end
				if deco then
					deco_used = true
				end
			end
		end

		if lvm_used then
			-- Write stuff
			vm:set_data(data)
			if param2 > 0 then
				vm:set_param2_data(data2)
			end
			if deco_used then
				minetest.generate_decorations(vm)
			end
			vm:calc_lighting(p1, p2, shadow)
			vm:write_to_map()
			vm:update_liquids()
		end
	end

	if nodes > 0 then
		for _, rec in ipairs(registered_generators) do
			if rec.nf then
				rec.nf(p1, p2, blockseed)
			end
		end
	end

	ran_structures.add_chunk(minp)
	if logging then
		minetest.log("action", "[mcl_mapgen_core] Generating chunk " .. minetest.pos_to_string(minp) .. " ... " .. minetest.pos_to_string(maxp).."..."..tostring(roundN(((os.clock() - t1)*1000),2)).."ms")
	end
end)

function minetest.register_on_generated(node_function)
	--ran_structures.register_generator("mod_"..minetest.get_current_modname().."_"..tostring(#registered_generators+1), nil, node_function)
	ran_structures.register_generator("mod_ran_structures_"..tostring(#registered_generators+1), nil, node_function)
end

function ran_structures.register_generator(id, lvm_function, node_function, priority, needs_param2)
	if not id then return end

	local priority = priority or 5000

	if lvm_function then lvm = lvm + 1 end
	if node_function then nodes = nodes + 1 end
	if needs_param2 then param2 = param2 + 1 end

	local new_record = {
		id = id,
		i = priority,
		vf = lvm_function,
		nf = node_function,
		needs_param2 = needs_param2,
	}

	table.insert(registered_generators, new_record)
	table.sort(registered_generators, function(a, b)
		return (a.i < b.i) or ((a.i == b.i) and a.vf and (b.vf == nil))
	end)
end

function ran_structures.unregister_generator(id)
	local index
	for i, gen in ipairs(registered_generators) do
		if gen.id == id then
			index = i
			break
		end
	end
	if not index then return end
	local rec = registered_generators[index]
	table.remove(registered_generators, index)
	if rec.vf then lvm = lvm - 1 end
	if rec.nf then nodes = nodes - 1 end
	if rec.needs_param2 then param2 = param2 - 1 end
	--if rec.needs_level0 then level0 = level0 - 1 end
end



------------------------------------------------------------------------------
--From mcl_mapgen_core init

ran_structures.register_generator("structures",nil, function(minp, maxp, blockseed)
	local gennotify = minetest.get_mapgen_object("gennotify")
	local has_struct = {}
	local has = false
	local poshash = minetest.hash_node_position(minp)
	for _,struct in pairs(ran_structures.registered_structures) do
		local pr = PseudoRandom(blockseed + 42)
		if struct.deco_id then
			for _, pos in pairs(gennotify["decoration#"..struct.deco_id] or {}) do
				local realpos = vector.offset(pos,0,1,0)
				minetest.remove_node(realpos)
				minetest.fix_light(vector.offset(pos,-1,-1,-1),vector.offset(pos,1,3,1))
				if struct.chunk_probability == nil or (not has and pr:next(1,struct.chunk_probability) == 1 ) then
					ran_structures.place_structure(realpos,struct,pr,blockseed)
					has=true
				end
			end
		elseif struct.static_pos then
			for _,p in pairs(struct.static_pos) do
				if in_cube(p,minp,maxp) then
					ran_structures.place_structure(p,struct,pr,blockseed)
				end
			end
		end
	end
	return false, false, false
end, 100, true)


-------------------------------------------------------------------------------
-- From mcl_init
ran_structures.chunksize = math.max(1, tonumber(minetest.get_mapgen_setting("chunksize")) or 5)
ran_structures.MAP_BLOCKSIZE = math.max(1, minetest.MAP_BLOCKSIZE or 16)
local central_chunk_offset = -math.floor(ran_structures.chunksize / 2)

ran_structures.MAX_MAP_GENERATION_LIMIT = math.max(1, minetest.MAX_MAP_GENERATION_LIMIT or 31000)
ran_structures.chunk_size_in_nodes = ran_structures.chunksize * ran_structures.MAP_BLOCKSIZE


local k_positive = math.ceil(ran_structures.MAX_MAP_GENERATION_LIMIT / ran_structures.chunk_size_in_nodes)
local k_positive_z = k_positive * 2
local k_positive_y = k_positive_z * k_positive_z


local function coordinate_to_block(x)
	return math.floor(x / ran_structures.MAP_BLOCKSIZE)
end

local function coordinate_to_chunk(x)
	return math.floor((coordinate_to_block(x) - central_chunk_offset) / ran_structures.chunksize)
end

function ran_structures.pos_to_chunk(pos)
	return {
		x = coordinate_to_chunk(pos.x),
		y = coordinate_to_chunk(pos.y),
		z = coordinate_to_chunk(pos.z)
	}
end

function ran_structures.get_chunk_number(pos) -- unsigned int
	local c = ran_structures.pos_to_chunk(pos)
	return
		(c.y + k_positive) * k_positive_y +
		(c.z + k_positive) * k_positive_z +
		 c.x + k_positive
end

local chunks = {} -- intervals of chunks generated
function ran_structures.add_chunk(pos)
	local n = ran_structures.get_chunk_number(pos) -- unsigned int
	local prev
	for i, d in pairs(chunks) do
		if n <= d[2] then -- we've found it
			if (n == d[2]) or (n >= d[1]) then return end -- already here
			if n == d[1]-1 then -- right before:
				if prev and (prev[2] == n-1) then
					prev[2] = d[2]
					table.remove(chunks, i)
					return
				end
				d[1] = n
				return
			end
			if prev and (prev[2] == n-1) then --join to previous
				prev[2] = n
				return
			end
			table.insert(chunks, i, {n, n}) -- insert new interval before i
			return
		end
		prev = d
	end
	chunks[#chunks+1] = {n, n}
end
