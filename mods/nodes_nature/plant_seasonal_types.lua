---------------------------------------------------------
--Plant seasonal types

-- Internationalization
local S = nodes_nature.S
nodes_nature = nodes_nature

---------------------------------------------------------

nodes_nature.seasonal_types = {
    early = {
        _spring_early = "_seedling3",
        _spring_late = "_flowering",
        _summer_early = "_fruiting",
        _summer_late = "_fruiting",
        _fall_early = "_fruiting",
        _fall_late = "_dead",
        _winter_early = "_dead",
        _winter_late = "_seed",
    },
    medium = {
        _spring_early = "_seed",
        _spring_late = "_seedling3",
        _summer_early = "_flowering",
        _summer_late = "_fruiting",
        _fall_early = "_fruiting",
        _fall_late = "_dead",
        _winter_early = "_dead",
        _winter_late = "_dead",
    },
    long = {
        _spring_early = "_seedling5",
        _spring_late = "_fruitless",
        _summer_early = "_flowering",
        _summer_late = "_fruiting",
        _fall_early = "_fruiting",
        _fall_late = "_fruiting",
        _winter_early = "_dead",
        _winter_late = "_dead",
    },
    late = {
        _spring_early = "_dead",
        _spring_late = "_seedling3",
        _summer_early = "_seedling5",
        _summer_late = "_flowering",
        _fall_early = "_fruiting",
        _fall_late = "_fruiting",
        _winter_early = "_dead",
        _winter_late = "_dead",
    },
    late_mushroom = {
        _spring_early = "_dead",
        _spring_late = "_seed",
        _summer_early = "_seed",
        _summer_late = "_seedling5",
        _winter_early = "_dead",
        _winter_late = "_dead",
    },
    wintery = {
        _spring_early = "_seed",
        _spring_late = "_seedling3",
        _summer_early = "_seedling5",
        _summer_late = "_flowering",
        _fall_early = "_flowering",
        _fall_late = "_fruiting",
        _winter_early = "_fruiting",
        _winter_late = "_dead",
    },
    mainly_flower = {
        _spring_early = "_seedling3",
        _spring_late = "_flowering",
        _summer_early = "_flowering",
        _summer_late = "_flowering",
        _fall_early = "_fruiting",
        _fall_late = "_dead",
        _winter_early = "_dead",
        _winter_late = "_seed",
    },
    early_flower = {
        _spring_early = "_flowering",
        _spring_late = "_flowering",
        _summer_early = "_fruiting",
        _summer_late = "_fruitless",
        _fall_early = "_fruitless",
        _fall_late = "_fruitless",
        _winter_early = "_dead",
        _winter_late = "_seed",
    },
    whole_season = {
        _spring_early = "_seedling5",
        _winter_early = "_dead",
        _winter_late = "_dead",
    },
    cane = {
        _winter_early = "_dead",
        _winter_late = "_dead",
    },
    whole_season_woody = {
        _winter_early = "_dead",
        _winter_late = "_dead",
    },
    succulent_flowering = {
        _spring_early = "_fruitless",
        _spring_late = "_flowering",
        _summer_early = "_flowering",
        _summer_late = "_fruiting",
        _fall_early = "_fruitless",
        _fall_late = "_fruitless",
        _winter_early = "_dead",
        _winter_late = "_dead",
    },
    tuber = {
        _spring_early = "_seedling5",
        _spring_late = "_flowering",
        _summer_early = "_fruiting",
        _summer_late = "_fruiting",
        _fall_early = "_fruitless",
        _fall_late = "_dead",
        _winter_early = "_dead",
        _winter_late = "_dead",
    },
}
-- local scope
do
  -- add missing values
  for _,st in pairs(nodes_nature.seasonal_types) do --
    st._spring_early = st._spring_early or ""
    st._spring_late = st._spring_late or ""
    st._summer_early = st._summer_early or ""
    st._summer_late = st._summer_late or ""
    st._fall_early = st._fall_early or ""
    st._fall_late = st._fall_late or ""
    st._winter_early = st._winter_early or ""
    st._winter_late = st._winter_late or ""
  end
end
