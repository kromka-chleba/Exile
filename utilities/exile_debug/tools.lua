-- make a tool that can in real-time show the traits of a node - pos, groups, name, etc

local nphud = {}

local hus = cheats.settings.hus 

local function get_table_length(table)
  local count = 0
  
  if (type(table) ~= "table") then
    error("get_table_length: no table provided")
  end
  
  for _,_ in pairs(table) do
    count = count + 1
  end
  
  return count
end


local function table_unpack(table)
  if (type(table) ~= "table") then
    return
  end
  
  local newt = {}
  
  local function add_content(lctable)
    for key,value in pairs(lctable) do
      if (type(value) == "table") then
        add_content(value)
      else
        newt[key] = value
      end
    end
  end
  
  add_content(table)
  
  return newt
end


local function create_hud_data(hudtype,datatable,settings)
  local bsettings = {
    titlepos = {x = .5, y = .15},
    titlecolour = 0xFFFF0B,
    split = 3,
    
    separation = 0.22,
    
    textsizemax = 33, -- for title
    textsizemax2 = 51, -- for title
    
    othertextsizemax = 110,
    
    colours = {
      ["groups"] = 0x0bffe1, -- light blue
      ["functions"] = 0xf58b0a, -- red-y orange
      ["sounds"] = 0xb71cd6, -- purple  --0xe01d6b, -- pink
      ["tiles"] = 0x179919, -- darkish green
      ["node_box"] = 0xbd7231, -- brown
      ["selection_box"] = 0xfc037b, -- reddish pink
      ["collision_box"] = 0x080099, -- dark blue
      
      ["node_timer"] = 0xDC1527, -- velvet-ish
      ["fields"] = 0xffd116, -- orange-ish yellow
      ["params"] = 0xce2af6, -- purple
      ["inventory"] = 0x0fffe7, -- toothpaste blue
      
      ["misc"] = 0xeaff05, -- yellow
      ["custom"] = 0x30ff29, -- saturated green
    },
    
    persist_colours = { -- do not resort to "othertext" colour for appendtable()
      [1] = "meta",
      [2] = "*",
    },
  }
  local sizeclasses = {
    ["title"] = {x = 3, y = 1},
    ["subtitle"] = {x = 2, y = 1},
    ["text"] = {x = 1, y = 1},
  }
  local scyc = { -- sizeclassesyconstraint
    ["title"] = 0.05,
    ["subtitle"] = 0.04,
    ["text"] = 0.02,
  }
  
  if (type(settings) ~= "table") then
    settings = bsettings
  end
  if (type(settings) == "table") then
    for key,value in pairs(bsettings) do
      if (type(settings[key]) ~= type(value)) then
        settings[key] = value
      end
    end
  end
  
  settings.colours["othertable"] = 0x206af5 -- mild blue
  settings.colours["othertext"] = 0x969696 -- grey
  
  if (type(hudtype) ~= "string" or type(datatable) ~= "table") then
    return
  end
  
  if (type(hudtype) == "string") then
    hudtype = string.lower(hudtype)
  end
  
  local huds = {}
  local GHpos = {x = 0, y = 0} -- Global HUD pos
  local GHPMT = {} -- Global HUD pos Matrix
  
  if (hudtype == "namepos" or hudtype == "posname") then
    local name = datatable.name
    local pos = datatable.pos
    local contents = datatable.contents
    
    if (type(name) ~= "string" or type(contents) ~= "table") then
      return
    end
    
    if (type(pos) == "table") then
      pos = minetest.pos_to_string(pos)
    end
    
    if (type(pos) ~= "string") then
      return
    end
    
    local GHpos = { -- Global HUD pos
      x = settings.titlepos.x,
      y = settings.titlepos.y,
    }
    
    huds[1] = {
      name = "title",
      
      text = name,
      
      size = "title",
      position = {x = GHpos.x, y = GHpos.y},
      
      number = settings.titlecolour,
    }
  
    if (string.len(name) >= settings.textsizemax) then
      huds[1].size = "subtitle"
      GHpos.y = (settings.titlepos.y + scyc.subtitle)
    else
      GHpos.y = (settings.titlepos.y + scyc.title)
    end
    if (string.len(name) >= settings.textsizemax2) then
      huds[1].size = "text"
      GHpos.y = (settings.titlepos.y + scyc.text)
    end
    
    huds[#huds + 1] = {
      name = "pos",
      
      text = pos,
      
      size = "text",
      
      position = {x = GHpos.x, y = GHpos.y},
      
      number = settings.titlecolour,
    }
    GHpos.y = GHpos.y + (scyc.text * 2)
    
    local conlen = get_table_length(contents)
    
    if (conlen < settings.split) then
      settings.split = conlen
    end
    
    local evenodd = settings.split % 2
    if (evenodd ~= 1) then
      evenodd = 0.5
    end
    
    if (settings.split > 1) then
      local starti = (settings.split - math.ceil(settings.split / 2))
      
      for i = starti, 1, -1 do
        local multiply = (i - evenodd) --( (starti - i) - evenodd ) --(settings.split - i)
        
        if (evenodd == 1) then
          multiply = i
        end
        
        if (multiply >= 0) then
          multiply = settings.separation * multiply
          
          GHPMT[#GHPMT + 1] = {x = (GHpos.x - multiply), y = GHpos.y}
        end
      end
      if (evenodd == 1) then
        GHpos.x = settings.titlepos.x
        
        GHPMT[#GHPMT + 1] = {x = GHpos.x, y = GHpos.y} -- GHpos.x - settings.separation
      end
      for i = 1, starti, 1 do
        local multiply = (i - evenodd) --(settings.split - i)
        
        if (evenodd == 1) then
          multiply = i
        end
        
        if (multiply >= 0) then
          multiply = settings.separation * multiply
          
          GHPMT[#GHPMT + 1] = {x = (GHpos.x + multiply), y = GHpos.y}
        end
      end
    else
      GHPMT[1] = {x = GHpos.x, y = GHpos.y}
    end
    
    local function GSCY(id,coord) -- Get Smallest Coordinate Y
      for i,ncoord in pairs(GHPMT) do
        if (ncoord.y < coord.y) then
          coord = ncoord
          id = i
        end
      end
      
      return id,coord
    end
    
    local function appendtable(table,coord,colour,islist)
      if (type(table) ~= "table") then
        return
      end
      
      if (type(islist) ~= "boolean") then
        islist = false
      end
      
      local parent_string = huds[#huds].name or ""
      
      local PC = false -- PersistColour
      
      if (type(settings.persist_colours) == "table") then
        for _,value in pairs(settings.persist_colours) do
          if (type(value) == "string") then
            if (value == "*") then
              PC = true
              break
            else
              value = settings.colours[value]
              if (type(value) == "number" and value == colour) then
                PC = true
                break
              end
            end
          elseif (type(value) == "number") then
            if (value == colour) then
              PC = true
              break
            end
          end
        end
      end
      
      for _,data in pairs(table) do
        local dname = data.name 
        local dinfo = data.data
        
        local ninfo
        
        if (type(dinfo) == "function") then
          dinfo = ""
        elseif (type(dinfo) == "table") then
          ninfo = {}
          for infoname,infodata in pairs(dinfo) do
            ninfo[#ninfo + 1] = {name = infoname,data = infodata}
          end
          
          dinfo = ";; {"
        else
          dinfo = tostring(dinfo)
          
          dinfo = string.gsub(dinfo,".png","")
          
          if (string.len(dinfo) >= settings.othertextsizemax) then
            dinfo = "limit"
          end
          
          if (dinfo ~= "limit" and dinfo ~= "") then
            dinfo = "="..dinfo
          end
        end
        
        local linelen = 1
        if (type(dinfo) == "string") then
          linelen = #string.split(dinfo,"\n")
        end
        
        if (dinfo == "limit" and linelen == 1) then
          dname = ""
          
          dinfo = "=text exceeded limit="
        end
        
        --if (colour == settings.colours["othertext"]) then
          --dinfo = dinfo
        --end
        
        if (linelen > 1) then
          coord.y = coord.y + scyc.text
        elseif (linelen ~= 1) then
          linelen = 1
        end
        
        huds[#huds + 1] = {
          name = parent_string.."."..dname,
          
          text = dname..dinfo,
          
          size = "text",
          
          position = {x = coord.x, y = coord.y},
          
          number = colour,
        }
        
        coord.y = coord.y + (scyc.text * linelen)
        
        if (type(ninfo) == "table") then
          local chosen_colour = settings.colours["othertext"]
          
          if (PC == true) then
            chosen_colour = colour
          end
          
          appendtable(ninfo,coord,chosen_colour,true)
        end
      end
      
      local lastentry = huds[#huds]
      
      if (islist == false) then
        coord.y = coord.y + 0.01
      elseif (type(lastentry) == "table") then
        lastentry.text = lastentry.text .. " };"
      end
    end
    
    for sbnameraw,sbdata in pairs(contents) do -- subtitle name (RAW), subtitle data
      local sbname = tostring(sbnameraw) -- in case not a string
      
      if (type(sbdata) == "table") then
        local colour = settings.colours[sbname]
        if (type(colour) ~= "number") then
          colour = settings.colours["othertable"]
        end
        
        local writeto = 1
        local coord = GHPMT[writeto]
        writeto,coord = GSCY(writeto,coord)
        
        huds[#huds + 1] = {
          name = "contents."..sbname,
          
          text = sbname,
          
          size = "subtitle",
          
          position = {x = coord.x, y = coord.y},
          
          number = colour,
        }
        
        coord.y = coord.y + scyc.subtitle
        
        local content = {}
        if (get_table_length(sbdata) > 0) then
          for i,v in pairs(sbdata) do
            if (type(v) == "string") then
              local split = string.split(v,"\n")
              
              if (#split > 1) then
                --v = split
              end
            end
            content[#content + 1] = {name = tostring(i),data = v}
          end
        else
          content = { {name = "{}",data = ""} }
        end
        
        appendtable(content,coord,colour)
      end
    end
    
  else
    return
  end
  
  if (type(huds) ~= "table") then
    return
  end
  
  for _,hude in pairs(huds) do -- hud element
    if (type(hude.size) == "string") then
      local size = sizeclasses[hude.size]
      if (type(size) == "table") then
        hude.size = sizeclasses[hude.size]
      else
        hude.size = sizeclasses.text
      end
    end
  end
  
  return huds
end



local function create_nphud_data(datatable,ttype)
  if (type(datatable) ~= "table") then
    return
  end
  
  local nodestats = datatable.nodestats
  local nodedata = datatable.nodedata
  local extra = datatable.extra 
  
  if (type(nodestats) == "nil" or type(nodedata) == "nil") then
    return
  end
  
  if (type(extra.name) ~= "string") then
    return
  end
  
  if (type(ttype) ~= "string") then
    ttype = "static"
  else
    ttype = string.lower(ttype)
  end
  
  if (type(extra.pos) ~= "string") then
    extra["pos"] = "no position found"
  end
  
  local huddata = {
    name = extra.name,
    pos = extra.pos,
    
    contents = {},
  }
  
  if (ttype == "static") then
    local functions = {}
    local misc = {}
    local custom = {}
    
    for key,value in pairs(nodedata) do
      local akey -- accepted key (if key - the name is acceptable, then set "akey" to it)
      
      if (key ~= "tiles" and string.match(key,"box") ~= "box") then
        akey = key
      end
      
      if (type(value) == "table" and type(akey) ~= "nil") then
        huddata.contents[akey] = value
      elseif (type(value) ~= "table") then
        if (type(value) == "function") then
          functions[key] = ""
        else
          if (type(key) == "string") then
            local iscustom = string.sub(tostring(key),1,1)
            if (iscustom == "_") then
              custom[key] = value
            else
              misc[key] = value
            end
          else
            misc[key] = value
          end
        end
      end
    end
    
    if (get_table_length(functions) > 1) then
      huddata.contents.functions = functions
    end
    if (get_table_length(misc) > 1) then
      huddata.contents.misc = misc
    end
    if (get_table_length(custom) > 1) then
      huddata.contents.custom = custom
    end
  elseif (ttype == "active") then
    
    local params = {}
    
    for key,value in pairs(nodestats) do
      local akey -- accepted key (if key - the name is acceptable, then set "akey" to it)
      
      if (key ~= "node_meta") then
        akey = key
      end
      
      if (type(value) == "table" and type(akey) ~= "nil") then
        huddata.contents[akey] = value
      elseif (string.match(key,"param")) then
        params[key] = value
      end
    end
    if (type(nodestats.node_meta) == "table") then
      for key,value in pairs(nodestats.node_meta) do
        local akey -- accepted key (if key - the name is acceptable, then set "akey" to it)
        
        if (key ~= "node_meta") then
          akey = key
        end
        
        if (type(value) == "table" and type(akey) ~= "nil") then
          huddata.contents[akey] = value
        elseif (string.match(key,"param")) then
          params[key] = value
        end
      end
    end
    
    if (get_table_length(params) > 1) then
      huddata.contents.params = params
    end
  end
  
  return create_hud_data("posname",huddata)
end

local function remove_hud(user,hname,id)
  if (type(user) ~= "userdata" or type(hname) ~= "string") then
    return
  end
  
  if (type(hname) == "string") then
    hname = string.lower(hname)
  end
  
  if (user:is_player() ~= true) then
    return
  end
  
  if (hname == "nphud") then
    local hud = nphud[user:get_player_name()]
    
    if (type(hud) ~= "table") then
      return
    end
    
    if (type(id) == "number") then
      if (hud.id ~= id) then
        return
      end
    end
    
    for _,gui in pairs(hud) do
      user:hud_remove(gui)
    end
    
    hud = {}
  end
end

local function create_hud(user,hname,...)
  local username
  
  if (type(hname) ~= "string") then
    return
  end
  
  if (type(hname) == "string") then
    hname = string.lower(hname)
  end
  
  if (type(user) == "userdata") then
    if (user:is_player() == true) then
      username = user:get_player_name()
    end
  elseif (type(user) == "string") then
    username = user
  end
  
  if (type(username) ~= "string") then
    return
  end
  
  if (hname == "nphud") then
    local huddata = create_nphud_data(...)
    
    if (type(huddata) ~= "table") then
      return
    end
    
    remove_hud(user,hname)
    
    nphud[username] = {}
      
    for name,gui in pairs(huddata) do
      if (type(gui) == "table") then
        nphud[username][name] = user:hud_add(gui)
      end
    end
  end
  
  local hud_id = math.random(1,5000000000)
  nphud[username]["id"] = hud_id
  
  return hud_id -- return a primitive "ID"
end





local function update_nphud(user,...)
  local newdata = create_nphud_data(...)
  
  if (type(user) ~= "userdata" or type(newdata) ~= "table") then
    return
  end
  
  if (user:is_player() ~= true) then
    return
  end
  
  local hud = nphud[user:get_player_name()]
  
  if (type(hud) ~= "table") then
    return 
  end
  
  for index,hudeid in pairs(hud) do
    local hude = user:hud_get(hudeid)
    
    if (index == "id") then
      hude = nil
    end
    
    if (type(hude) == "table") then
      local name = hude.name
      
      for _,newhude in pairs(newdata) do
        if (type(newhude) == "table") then
          local nname = newhude.name
          local ntext = newhude.text
          
          if (name == nname and type(ntext) == "string") then
            user:hud_change(hudeid,"text",ntext)
          end
        end
      end
    end
  end
end

local function updateNodeProbeHUD(itemstack,user,id,pos,...)
  if (type(user) == "userdata" and type(itemstack) == "userdata") then
    local hud = nphud[user:get_player_name()]
    if (itemstack:to_string() == user:get_wielded_item():to_string() and type(hud) == "table") then
      if (hud.id == id) then
        update_nphud(user,cheats.node_properties(pos),...)
        minetest.after(hus, updateNodeProbeHUD,  itemstack,user,id,pos,... )
        return
      end
    end
  end
  
  remove_hud(user,"nphud",id)
  
  return
end






local function ndprobe_rightclick(itemstack, user, pointed_thing)
  remove_hud(user,"nphud")
  
  local pos = pointed_thing.under
  
  local hudid = create_hud(user,"nphud",cheats.node_properties(pos),"active")
    
  if (type(hudid) == "number") then
    updateNodeProbeHUD(itemstack,user,hudid,pos,"active")
  end
end

minetest.register_craftitem("cheats:node_probe", {
	description = "Node Probe",
	inventory_image = "cheats_node_detector.png",
  wield_image = "cheats_node_detector.png^[transformR90",
	stack_max = 1,

	on_use = function(itemstack, user, pointed_thing)
    remove_hud(user,"nphud")
    
		local pos = pointed_thing.under
    
    local hudid = create_hud(user,"nphud",cheats.node_properties(pos),"static")
    
    if (type(hudid) == "number") then
      updateNodeProbeHUD(itemstack,user,hudid,pos,"static")
    end
	end,
  
  on_place = function(itemstack, user, pointed_thing)
    ndprobe_rightclick(itemstack, user, pointed_thing)
  end,
  
  on_secondary_use = function(itemstack, user, pointed_thing)
    ndprobe_rightclick(itemstack, user, pointed_thing)
  end,
  
})