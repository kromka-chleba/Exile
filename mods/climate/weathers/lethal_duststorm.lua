------------------------------
-- Lethal Duststorm
-- clouds of dust
-- sky color yellowish, damaging, lots of thunder
------------------------------

local lethal_duststorm = {}
lightning = lightning

lethal_duststorm.name = 'lethal_duststorm'


lethal_duststorm.sky_data = {
    type = "regular",
    clouds = true,
    sky_color = {
        day_sky = "#F4DFBE",
        day_horizon = "#f6e5cb",
        dawn_sky = "#F9A09C",
        dawn_horizon ="#fab3af",
        night_sky = "#513200",
        night_horizon = "#735a32",
        indoors = "#2B2B2B",
        --fog_sun_tint = "#FB7F55",
        --fog_moon_tint = "#C5C9C9",
        --fog_tint_type = "custom"
    },
    body_orbit_tilt = 5
}


lethal_duststorm.cloud_data = {
    color = "#ac9673",
    density = 0.6,
    height = 100,
    thickness = 180,
    speed = {x=0, z=4}
}


lethal_duststorm.moon_data = {
    visible = false,
    texture = "moon.png",
    tonemap = "moon_tonemap.png",
    scale = 0.5
}


lethal_duststorm.sun_data = {
    visible = false,
    texture = "sun.png",
    tonemap = "sun_tonemap.png",
    sunrise = "sunrisebg.png",
    sunrise_visible = false,
    scale = 0.4
}

lethal_duststorm.star_data = {
    visible = false,
    count = 2000,
    color = "#80FCFEFF",
    star_seed = minetest.get_mapgen_setting("seed")
}




lethal_duststorm.sound_loop = 'duststorm_loop'

lethal_duststorm.damage = true


--probabilities in each temp class
lethal_duststorm.chain = {
    --name, p_froz, p_cold, p_mid , p_hot
    {'duststorm', 1, 1, 0.97, 0.75}

}

lethal_duststorm.particle_interval = 0.0007

lethal_duststorm.particle_function = function(player)
    local velxz = math.random(-5, 2)
    local vely = math.random(-3, 2)
    local accxz = math.random(-3,2)
    local accy = math.random(-2, 2)
    local ext = 10
    local size = 20
    local tex = "duststorm.png"

    climate.add_blizzard_particle(velxz, vely, accxz, accy, ext, size,
                                  tex, player)

    if math.random() < 0.01 then
        lightning.strike()
    end
end


--add this weather to register
climate.register_weather(lethal_duststorm)


------
