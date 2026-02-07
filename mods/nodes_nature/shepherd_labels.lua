---------------------------------------------
-- Only shepherd labels go here

mapchunk_shepherd = mapchunk_shepherd
local ms = mapchunk_shepherd

-- Soil
ms.tag.register("no_soil")
ms.tag.register("bare_soil")
ms.tag.register("spring_soil")
ms.tag.register("winter_soil")

-- Moisture
ms.tag.register("moisture_spread")
ms.tag.register("water_gravity")

-- Plants
ms.tag.register("spring_early_plants")
ms.tag.register("spring_late_plants")
ms.tag.register("summer_early_plants")
ms.tag.register("summer_late_plants")
ms.tag.register("fall_early_plants")
ms.tag.register("fall_late_plants")
ms.tag.register("winter_early_plants")
ms.tag.register("winter_late_plants")
ms.tag.register("seasonal_plants")
ms.tag.register("seasonal_trees")

-- Trees
ms.tag.register("leaves_dropped")
ms.tag.register("leaves")

-- Weather
ms.tag.register("last_rain")
ms.tag.register("last_snow")
ms.tag.register("last_evaporated")
ms.tag.register("last_thawed")
ms.tag.register("last_freezed")

-- Biomes
ms.tag.register("ocean")
ms.tag.register("coast")
ms.tag.register("mountains")

-- Note: surface, underground, aboveground tags are provided by shepherd's common_tags.lua
