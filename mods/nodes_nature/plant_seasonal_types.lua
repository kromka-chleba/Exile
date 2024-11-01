---------------------------------------------------------
--Plant seasonal types

-- Internationalization
local S = nodes_nature.S
nodes_nature = nodes_nature

---------------------------------------------------------
nodes_nature.seasonal_types = {}
-- permit registering custom seasonal types
function nodes_nature.register_seasonal_type(name, def)
    def.spring_early = def.spring_early or ""
    def.spring_late = def.spring_late or ""
    def.summer_early = def.summer_early or ""
    def.summer_late = def.summer_late or ""
    def.fall_early = def.fall_early or ""
    def.fall_late = def.fall_late or ""
    def.winter_early = def.winter_early or ""
    def.winter_late = def.winter_late or ""
    -- set names properly for usage for nodes to a new table
    local fixdef = {}
    -- add underscore to bottom of tag and value
    for tag,val in pairs(def) do
        -- add underscore before value
        if val ~= "" then
            val = val:sub(1,1) ~= "_" and "_"..val or val
        end
        fixdef["_"..tag] = val
    end
    nodes_nature.seasonal_types[name] = fixdef
    return def
end

local st_list = {
    early = {
        spring_early = "seedling3",
        spring_late = "flowering",
        summer_early = "fruiting",
        summer_late = "fruiting",
        fall_early = "fruiting",
        fall_late = "dead",
        winter_early = "dead",
        winter_late = "seed",
    },
    medium = {
        spring_early = "seed",
        spring_late = "seedling3",
        summer_early = "flowering",
        summer_late = "fruiting",
        fall_early = "fruiting",
        fall_late = "dead",
        winter_early = "dead",
        winter_late = "dead",
    },
    long = {
        spring_early = "seedling5",
        spring_late = "fruitless",
        summer_early = "flowering",
        summer_late = "fruiting",
        fall_early = "fruiting",
        fall_late = "fruiting",
        winter_early = "dead",
        winter_late = "dead",
    },
    late = {
        spring_early = "dead",
        spring_late = "seedling3",
        summer_early = "seedling5",
        summer_late = "flowering",
        fall_early = "fruiting",
        fall_late = "fruiting",
        winter_early = "dead",
        winter_late = "dead",
    },
    late_mushroom = {
        spring_early = "dead",
        spring_late = "seed",
        summer_early = "seed",
        summer_late = "seedling5",
        winter_early = "dead",
        winter_late = "dead",
    },
    wintery = {
        spring_early = "seed",
        spring_late = "seedling3",
        summer_early = "seedling5",
        summer_late = "flowering",
        fall_early = "flowering",
        fall_late = "fruiting",
        winter_early = "fruiting",
        winter_late = "dead",
    },
    mainly_flower = {
        spring_early = "seedling3",
        spring_late = "flowering",
        summer_early = "flowering",
        summer_late = "flowering",
        fall_early = "fruiting",
        fall_late = "dead",
        winter_early = "dead",
        winter_late = "seed",
    },
    early_flower = {
        spring_early = "flowering",
        spring_late = "flowering",
        summer_early = "fruiting",
        summer_late = "fruitless",
        fall_early = "fruitless",
        fall_late = "fruitless",
        winter_early = "dead",
        winter_late = "seed",
    },
    whole_season = {
        winter_early = "dead",
        winter_late = "dead",
    },
    whole_season_seedling = {
        spring_early = "seedling5",
        winter_early = "dead",
        winter_late = "dead",
    },
    succulent_flowering = {
        spring_early = "fruitless",
        spring_late = "flowering",
        summer_early = "flowering",
        summer_late = "fruiting",
        fall_early = "fruitless",
        fall_late = "fruitless",
        winter_early = "dead",
        winter_late = "dead",
    },
    tuber = {
        spring_early = "seedling5",
        spring_late = "flowering",
        summer_early = "fruiting",
        summer_late = "fruiting",
        fall_early = "fruitless",
        fall_late = "dead",
        winter_early = "dead",
        winter_late = "dead",
    },
}

-- register all seasonal types
for name, def in pairs(st_list) do
    nodes_nature.register_seasonal_type(name, def)
end