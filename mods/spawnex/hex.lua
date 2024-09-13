--------------------------------------------------------------------------
-- Hex layer

-- hex grid centered on 0,0, designated by hex = {x, z}, +/- hex numbers
-- centerline 0, 15.5 hexes vert, 7 north/7 south, 17.7 horiz,8 east/8 west
-- total +/0 30,000 nodes north/south, +/- 29,444 west/east, 255 hexes total

math = math
local clamp = minimal.math_clamp


local apothem = 2000 -- height of triangle, distance from center edge to point
local tri_side = apothem / math.sqrt(3)*2 -- length of the side of the triangles
-- hex is assembled from six equilateral triangles, height 2000 side ~2290
local horz_dist = tri_side * 1.5 -- h distance between hex columns, ~4580
local stack_height = apothem * 2 -- v distance between hex rows, 4000

local function hexclamp(hex)
    return { clamp(hex[1], -8, 8),
             clamp(hex[2], -7, 7) }
end

local function hexequals(hex1, hex2)
    local h1 = hexclamp(hex1) local h2 = hexclamp(hex2)
    if h1[1] == h2[1] and h1[2] == h2[2] then
        return true
    end
    return false
end

local function hexnum(hex)
    local x, z = unpack(hex)
    x = x + 7 ; z = z + 8 -- remove negative offset
    return x + (z * 15)
end

local function hex2string(hex)
    return tostring(hex[1])..":"..tostring(hex[2])
end

local function string2hex(input)
    if type(input) ~= "string" then return end
    local hx, hz
    if string.match(input, ":") then -- "col:row" format
        hx, hz = unpack(string.split(input, ":"))
    else -- Try "col row" format
        hx, hz = string.match(input, "^([^ ]+) *(.*)$")
    end
    hx = tonumber(hx) hz = tonumber(hz)
    if not hx or not hz then return end
    return hexclamp({hx, hz})
end

local function hex2map(hex, y)
    if not y then y = 0 end
    local col, row = unpack(hexclamp(hex))
    local x = col*horz_dist
    local isodd = math.abs(col) %2
    local z = ( row * stack_height )
    z = z + (apothem * isodd) -- add vertical offset
    return vector.new(math.round(x), math.round(y), math.round(z))
end

local function map2hex(pos)
    -- Finds the closest hex to this pos, basically reverse the above.
    local col = math.round(pos.x / horz_dist)
    local isodd = math.abs(col) %2
    local row = pos.z - (apothem * isodd) -- remove offset
    row = math.round(row / stack_height)
    if tostring(col) == "-0" then col = 0 end -- Oh lua, you so crazy!
    if tostring(row) == "-0" then row = 0 end -- ( -0 does not equal 0 )
    return {col, row}  -- hex table
end

local dirtable = {
    --   1n      2ne      3se       4s      5sw      6nw
    { { 0, 1}, { 1, 0}, { 1,-1}, { 0,-1}, {-1,-1}, {-1, 0} }, -- even
    { { 0, 1}, { 1, 1}, { 1, 0}, { 0,-1}, {-1, 0}, {-1, 1} }, -- odd
}
local dirstring = {
    {"north"," N"}, {"northeast", "NE"}, {"southeast","SE"},
    {"south"," S"}, {"southwest", "SW"}, {"northwest","NW"} }

local function get_neighbor(hex, dir)
    local hx, hy = unpack(hexclamp(hex))
    local mx, my = unpack(dirtable[hx%2 + 1][dir])
    local neighbor = hexclamp({ hx + mx, hy + my })
    if hexequals(hex, neighbor) then return {} end
    return neighbor
end

local function get_neighbors(hex)
    local list = {}
    for dir = 1,6 do
        local new = get_neighbor(hex, dir)
        list[dir] = new
    end
    return list
end

local function distance_to_hex(pos, hex)
    if not vector.check(pos) then return end
    local hexpos = hex2map(hex, pos.y)
    if not vector.check(hexpos) then return end
    return math.round(pos:distance(hexpos))
end

local function hexdir_from_look_horiz(lookhoriz)
    local degrees = (lookhoriz * 180.0 / math.pi)
    local dir = math.round(degrees / 60) + 1
    if dir == 7 then dir = 1 end
    return dir
end

return dirstring, hexnum, hex2string, string2hex, hex2map, map2hex,
    get_neighbor, get_neighbors, distance_to_hex, hexdir_from_look_horiz
