-- GUI related stuff

function EXILE.set_hotbar(player,pref)
    if pref == "true" then
        -- use wide hotbar
        player:hud_set_hotbar_image("gui_hotbar16.png")
        player:hud_set_hotbar_itemcount(16)
        EXILE.update_hotbar_slotnums(player,16)
    else
        player:hud_set_hotbar_image("gui_hotbar.png")
        player:hud_set_hotbar_itemcount(8)
        EXILE.update_hotbar_slotnums(player,8)
    end
end

local blinkingbar = {}

function EXILE.hotbar_blink(player, color)
    if not minetest.is_player(player) then return end
    local pname = player:get_player_name()
    if blinkingbar[pname] then return end
    local img = player:hud_get_hotbar_image()
    if type(color) ~= "string" then color = "#000" end
    player:hud_set_hotbar_image(img.."^[colorize:"..color)
    blinkingbar[pname] = true
    minetest.after(0.5, function()
                       if minetest.is_player(player) then
                           player:hud_set_hotbar_image(img)
                       end
                       blinkingbar[pname] = nil
    end)
end

function EXILE.warn_inv_full(player)
    if minetest.is_player(player) then
        EXILE.hotbar_blink(player, "#F33")
        minetest.sound_play("failure",
                            {to_player = player:get_player_name()})
    end
end

local mtinvburst = minetest.settings:get_bool("exile_drop_on_full_inv")
function EXILE.stop_on_inv_full(player)
    if minetest.is_player(player) then
        local invburst = player:get_meta():get_string("drop_on_full_inv")
        if ( not invburst and mtinvburst ) or invburst == "true" then
            return false
        end
        EXILE.warn_inv_full(player)
        return true
    end
end

minetest.register_on_joinplayer(function(player)
        -- Set formspec prependl
        local meta = player:get_meta()
        EXILE.apply_gui_theme(player, meta)
        -- Set hotbar textures
        local hud = meta:get_string("hud16")
            or minetest.settings:get('exile_hud_wide_hotbar')
            or 'false'
        EXILE.set_hotbar(player,hud)
        player:hud_set_hotbar_selected_image("gui_hotbar_selected.png")
end)


function EXILE.get_hotbar_bg(x,y)
    local out = ""
    for i=0,7,1 do
        out = out .."image["..x+i..","..y..";1,1;gui_hb_bg.png]"
    end
    return out
end

