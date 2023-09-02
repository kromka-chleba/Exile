---------------------------------------------
-- Only shepherd labels go here

local ms = mapchunk_shepherd

-- Soil
ms.labels.register("no_soil")
ms.labels.register("bare_soil")
ms.labels.register("spring_soil")
ms.labels.register("winter_soil")
ms.labels.register("no_spring_soil")
ms.labels.register("no_winter_soil")

-- Moisture
ms.labels.register("moisture_spread")
ms.labels.register("water_gravity")

-- Plants
ms.labels.register("spring_early_plants")
ms.labels.register("spring_late_plants")
ms.labels.register("summer_early_plants")
ms.labels.register("summer_late_plants")
ms.labels.register("fall_early_plants")
ms.labels.register("fall_late_plants")
ms.labels.register("winter_early_plants")
ms.labels.register("winter_late_plants")
ms.labels.register("seasonal_plants")
ms.labels.register("seasonal_trees")

-- Trees
ms.labels.register("leaves_dropped")
ms.labels.register("leaves")

-- Weather
ms.labels.register("last_rain")
ms.labels.register("last_snow")
ms.labels.register("last_evaporated")
ms.labels.register("last_thawed")
ms.labels.register("last_freezed")

-- Biomes
ms.labels.register("ocean")
ms.labels.register("coast")
ms.labels.register("mountains")
