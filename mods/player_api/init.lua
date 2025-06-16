-- player/init.lua

player_api = {}
local modpath = minetest.get_modpath("player_api")

-- register the formspec page using player's state to display
--[[ thoses pages are refreshed on globalsteps (every 1 min and every 4 sec +)
    --and on join player in HEALTH (init.lua and on_actions.lua),
    --when the player's state change]]
local page_list = {}
function player_api.register_page_name(page_name)
    table.insert(page_list, page_name)
end

--[[update formspec display
    so we can see changes while looking on opened formspec
    or have correct display on opening (no inventory open callback)]]
function player_api.refresh_formspec_states(player)
    --[[since health states are not displayed in every tab,
    refresh sfinv only if this is the active page.
    Avoids unecesseray refresh of crafting formspec.]]
    for _, page_name in pairs(page_list) do
        if sfinv.get_page(player) == page_name then
            sfinv.set_player_inventory_formspec(player)
            break
        end
    end
end

dofile(modpath .. "/states.lua")
dofile(modpath .. "/hand.lua")
dofile(modpath .. "/base_texture.lua")
dofile(modpath .. "/api.lua")
dofile(modpath .. "/controls.lua")
dofile(modpath .. "/clothing/init.lua") -- ex cloths.lua + ex "clothing" mod

animation_table = {
    -- Standard animations.
    stand         = {x = 0,   y = 80},
    sit           = {x = 81,  y = 161},
    lay           = {x = 162, y = 167},
    walk          = {x = 168, y = 188},
    mine          = {x = 189, y = 199},
    walk_mine     = {x = 200, y = 220},
    float         = {x = 225, y = 245},
    float_mine    = {x = 250, y = 270},
    swim          = {x = 275, y = 315},
    swim_mine     = {x = 320, y = 360},
    crouch        = {x = 365, y = 375},
    crouch_mine   = {x = 380, y = 390},
    crawl         = {x = 395, y = 415},
    crawl_mine    = {x = 420, y = 440},
}

-- Default player appearance
player_api.register_model("character.b3d", {
    animation_speed = 30,
    textures = {"character.png"},
    animations = animation_table,
    collisionbox = {-0.3, 0.0, -0.3, 0.3, 1.7, 0.3},
    stepheight = 0.6,
    eye_height = 1.45,
})

--Just a copy of the male model, but with a smaller visual_size applied
--Minetest doesn't allow you to register one model two ways
--TODO: Find/make better models
player_api.register_model("character-f.b3d", {
    animation_speed = 30,
    textures = {
        "female.png",
        "3d_armor_trans.png",
        "3d_armor_trans.png",
    },
    animations = animation_table,
    collisionbox = {-0.3, 0.0, -0.3, 0.3, 1.7, 0.3},
    visual_size = { x =.8, y = .94, z = .8 },
    stepheight = 0.6,
    eye_height = 1.38,
})

local function initialize_player (player)
    local player_name = player:get_player_name()
    player_api.player_attached[player_name] = false
    local gender = player_api.get_gender(player)
    if gender == "" then
        player_api.set_gender(player, "random") --set random gender
    end

    local pinv = player:get_inventory()
    pinv:set_size("hand", 2)
    -- create the "clothes" inventories if needed
    -- also amange migrations issues
    player_api.set_cloths(player) -- init and migrates inv if needed
    player_api.set_texture(player) -- setting texture according to current state

    -- set default clothing (I think ?)
    local cloth = player_api.compose_cloth(player) -- but we did compose it in set_texture

    player_api.update_equipment_effects(player) -- #TODO do we separate that part ?

    local gender_model = player_api.get_gender_model(gender)
    player_api.registered_models[gender_model].textures[1] = cloth
    player_api.set_model(player, gender_model)
end

-- Update appearance when the player joins
minetest.register_on_joinplayer(function(player)
    initialize_player (player)

    --[[by default, if no context is created,
        we get the defautl sfinv homepage.
    set our page to clothing formspec while player is initialized
    (the formspec needs the texture to display the model)
        ]]
    sfinv.set_page(player, "clothing:clothing")
end)
