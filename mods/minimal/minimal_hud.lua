local m_hud_data = {} -- minimal hud

m_hud_data.quickslot = {}

local hud_scale = minetest.settings:get("gui_scaling") or 1
local hud_vert_pos	= -128 * hud_scale -- all HUD icon vertical position -- grabbed from HEALTH/hud.lua

local quickslot_settings = {
  font_w = 8,
  font_h = 15,
  
  quickslot_size = 56,
  quickslot_borderw = 5,
  quickslotnum_color = "FFFFFF",
  quickslotnum_offset = 2,
}

minimal.update_quickslot = function(player,slotnum) -- please don't provide it uneven numbers lol
  if not (minetest.is_player(player) and type(slotnum) == "number") then
    return
  end
  
  slotnum = minimal.math_clamp(math.ceil(slotnum),2,32)
  
  local quickslot = m_hud_data.quickslot[player:get_player_name()]
  
  if (type(quickslot) ~= "table") then
    quickslot = {}
    m_hud_data.quickslot[player:get_player_name()] = quickslot
  end
  local prevcount = quickslot.prevcount
  if (prevcount == tostring(slotnum)) then -- don't refresh the hud if the provided number is the same
    return
  end
  quickslot.prevcount = tostring(slotnum) -- convert to string to avoid confusion with hud_id deletion
  
  for _,hudid in pairs(quickslot) do
    if (type(hudid) == "number") then
      player:hud_remove(hudid)
    end
  end
  
  local quickslotnum_y	= (quickslot_settings.quickslot_size + quickslot_settings.font_h + quickslot_settings.quickslotnum_offset + quickslot_settings.quickslot_borderw) * hud_scale   -- quickslotnum text baseline height
  
  local count = 1 -- create artificial count because I'd rather the for loop do mathy cool stuff
  for i = -(math.ceil(slotnum / 2)), math.ceil((slotnum / 2) - 1), 1 do
    local borderw = quickslot_settings.quickslot_borderw
    if (count > 9) then -- make the 10s look nice
      borderw = borderw * 2
    end
    local slot = (borderw + quickslot_settings.quickslotnum_offset + quickslot_settings.quickslot_size*i) * hud_scale -- cool calculation that henczati made
    
    slot = {
      hud_elem_type = "text",
      offset = {x = slot, y = hud_vert_pos + quickslotnum_y},
      position = {x = .5, y = 1},
      number = tonumber("0x"..quickslot_settings.quickslotnum_color), --make it very visible
      text = count
    }
    
    slot = player:hud_add(slot)
    
    quickslot[count] = slot
    
    count = count + 1
  end
end