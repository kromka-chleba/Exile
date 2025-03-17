minimal = minimal
zone = zone

function minimal.vmanip_subregion(pos1, pos2, p1, p2)
    -- Creates parameters to a for loop that will cover an x/y/z subregion of a
    --  voxelmanip's flat array. Parameters pos1/2 are the subregion you wish to
    --  work with, while p1/2 are the full extent of the voxelmanip area

    -- For example:
    --  local VM_area1, VM_area2 = VoxelManip:read_from_map(MyPos1, MyPos2)
    --  retv = vmanip(subregion(MyPos1, MyPos2, VM_area1, VM_area2)
    --  for z = retv.zstart, retv.zstop, retv.zstep do
    --    for y ... -- (as above)
    --      for x ...
    --        local index = x+y+z ; data[index] = my_node_cid
    --

    -- First we get dimensions for the VM array
    local xl = p2.x - p1.x + 1 -- X length of the whole VM area, count from 1
    local yl = p2.y - p1.y + 1 -- Y length
    local zl = p2.z - p1.z + 1 -- Z length
    local zstep = xl*yl local ystep = xl local xstep = 1
    local size = zstep*zl -- how big the flat array is
    -- now we figure offsets for pos1 vs p1, pos2 vs p2, so we can shave them off
    local xs = pos1.x - p1.x local xe = pos2.x - p2.x -- x start / end
    local ys = (pos1.y - p1.y) * xl -- y start / end
    local ye = (pos2.y - p2.y) * xl -- distance from ends of a z chunk
    local zs = (pos1.z - p1.z) * yl*xl -- z start/end
    local ze = (pos2.z - p2.z) * yl*xl-- distance from the ends of the vm array
    return { zstart = zs, zstop = size+ze-zstep, zstep = zstep,
             -- we subtract zstep to reduce the end by 1 or else we'll run over
             ystart = ys, ystop = zstep+ye-ystep, ystep = ystep,
             xstart = xs, xstop = xl+xe-xstep, xstep = xstep
    }
end


--------------------------------------------------------------------------------
-- Loading/saving regions for tutorial, etc

local vmanip_subregion = minimal.vmanip_subregion
local zone_instance = zone.instance
local worldpath=minetest.get_worldpath()

function minimal.save_region(opos1, opos2, name)
    -- Stores the specified area as an .ex_schm file in the world folder

    local cids = { } -- like: { -1 = "unknown", 0 = "ignore", 1 = "air", etc. }
    local dat = {}
    local VoxelManip = minetest.get_voxel_manip()

    local pos1, pos2 = vector.sort(opos1, opos2)
    local p1, p2 = VoxelManip:read_from_map(pos1, pos2)
    local VoxAr = VoxelArea:new({MinEdge=p1, MaxEdge=p2})
    local nodes = VoxelManip:get_data()
    local param2 = VoxelManip:get_param2_data()
    local tmplist = minetest.find_nodes_with_meta(pos1, pos2)
    local mlist = {}
    for i = 1, #tmplist do -- convert pos values to index values
        mlist[VoxAr:indexp(tmplist[i])] = tmplist[i]
    end

    --local light = vm:get_light_data() -- do we need to store light values?

    local r = vmanip_subregion(pos1, pos2, p1, p2)
    for z = r.zstart, r.zstop, r.zstep do
        for y = r.ystart, r.ystop, r.ystep do
            for x = r.xstart, r.xstop, r.xstep do
                local index = x+y+z+1
                local this = nodes[index]
                if not cids[this] then
                    cids[this] = minetest.get_name_from_content_id(this)
                end
                local met
                if mlist[index] then
                    local meta = minetest.get_meta(mlist[index])
                    met = meta:to_table()
                    if met.inventory then
                        met.inventory = minimal.invlists2string(met.inventory)
                    end
                end
                if param2[index] == 0 and not met then
                    table.insert(dat, this) -- save id alone
                else
                    table.insert(dat, {id = this, p2 = param2[index], meta = met })
                end
            end
        end
    end
    local out = { "ex_schm_v1.0",
                  { pos1 = pos1, pos2 = pos2 },
                  cids,
                  dat
    }
    local f = io.open(worldpath.."/"..name..".ex_schm","wb")
    f:write(minetest.compress(minetest.serialize(out), "deflate"))
    f:close()
    return "Saved successfully"
end

local function open_region_file(f)
    -- Returns a table of {version, range, cids, data }
    -- or nil and an error message
    --   local fname = name..".ex_schm"
    --   local f = io.open(fname,"rb")
    if not f then
        local err = "EX_SCHM ERROR: File not found"
        minetest.log("action", err)
        return nil, err
    end
    local read = f:read("*all")
    local inp = minetest.decompress(read, "deflate")
    f:close()
    local input = minetest.deserialize(inp)
    if not input then
        local err =  "EX_SCHM ERROR: Read failed"
        minetest.log("action", err)
        return nil, err
    end
    return input
end

local function translate_cids(cid_in)
    local out = {}
    for id, name in pairs(cid_in) do
        if core.registered_nodes[name] then
            local new_id = core.get_content_id(name)
            out[id] = new_id
        else
            out[id] = core.get_content_id("air")
            core.log("Warning: Ex_Schm contains unknown node "..name..
                     " ; placed as air instead")
        end
    end
    return out
end

function minimal.load_region(base_raw, file)
    -- Loads a stored region and builds it on the map

    local benchmark = minetest.get_us_time()
    local input, err = open_region_file(file)
    if not input then return nil, err end
    local version, range, cids, dat = unpack(input)
    minetest.log("action", ("Found ex_schm version "..
                            version:gsub("ex_schm_","").." and loaded"))
    local partway = minetest.get_us_time() - benchmark
    minetest.log("action", "File read time: "..tostring(partway).." us")


    benchmark = minetest.get_us_time()

    local translated_ids = translate_cids(cids)

    local base = vector.round(base_raw)
    local xlate = vector.subtract(base, range.pos1) -- for translating pos values
    local pos1 = base
    local pos2 = vector.add(range.pos2, xlate)
    local VoxelManip = minetest.get_voxel_manip()
    local p1, p2 = VoxelManip:read_from_map(pos1, pos2)
    local VoxAr = VoxelArea:new({MinEdge=p1, MaxEdge=p2})
    local r = vmanip_subregion(pos1, pos2, p1, p2)
    local nodes = VoxelManip:get_data()
    local param2 = VoxelManip:get_param2_data()
    local count = 1
    for z = r.zstart, r.zstop, r.zstep do
        for y = r.ystart, r.ystop, r.ystep do
            for x = r.xstart, r.xstop, r.xstep do
                local index = x+y+z+1
                local this = dat[count]
                if type(this) == "number" then
                    this = { id = this, p2 = 0 }
                end -- id only
                nodes[index] = translated_ids[this.id]
                param2[index] = this.p2
                local tpos = VoxAr:position(index)
                if this.meta then
                    if this.meta.inventory then
                        this.meta.inventory =
                            minimal.string2invlists(this.meta.inventory)
                    end
                    local tmeta = this.meta.fields
                    if tmeta.ztr_id then -- it's a zone, create an instance
                        this.meta.fields = zone_instance(tpos, tmeta)
                    end
                    minetest.get_meta(tpos):from_table(this.meta)
                end
                count = count + 1
            end
        end
    end
    VoxelManip:set_data(nodes)
    VoxelManip:set_param2_data(param2)
    --VoxelManip:calc_lighting()
    VoxelManip:write_to_map()
    zone_instance("close") -- close the instancer and fire up all loaded zones
    benchmark = minetest.get_us_time() - benchmark
    minetest.log("action", "Setup time: "..tostring(benchmark).." us")
end

function minimal.get_region_size(name)
    -- Returns a table of {pos1 = , pos2 = } or nil and an error message
    local fname = worldpath.."/"..name..".ex_schm"
    local input, err = open_region_file(io.open(fname, "rb"))
    if not input then return nil, err end
    local _, range = unpack(input)
    return range
end
function minimal.load_region_raw(name)
    local input, err = open_region_file(io.open(name, "rb"))
    return input, err and err..": "..name or nil
end
