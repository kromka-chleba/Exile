-- he mod sfinv provides basic means to coordinate which  formspec is displayed
-- as inventory formspec at what time.
-- `sfinv`: A global table to manage fromspecs used as inventory GUI, i.e.
--          formspecs passed as parameter to set_inventoy_formspec() at certain
--          points to have them displayed when a player triggers the inventory
--          key.
-- elements:
-- `context`: one context object for inventory formspecs per player
-- `context.page`: used to track the name of the registered formspec that is
--            currently set as the player's inventory formspec, i.e. the
--            formspec that will open next time the player triggers the
--            inventory key
--            NOTE Due to limitiations of the engine, `sfinv` cannot track the
--                 current formspec automatically. Therefore it provides a
--                 wrapper to be called instead of `set_inventory_formspec()`,
--                 see `set_player_inventory_formspec()`.
--                 Calling `set_inventory_formspec()` directly means there
--                 has to be other mechanisms in order to synchonize with
--                 `sfinv`.
--                 Also it is not possible to use formspecs with `sfinv`
--                 without prior registration via `sfinv.register_page()`.
--       `...`: incomplete
-- `pages`: table of registered formspecs (name -> page),
--          see `register_page()`, `override_page()`, `remove_page()`
-- `pages_unordered`: ...
-- `enabled`: switch to disable `sfinv's` callback to set a default `homepage`
--            inventory formspec when a player joins; enabled by default
--            NOTE It is also possible to replace the `homepage` by providing a
--                 a different name, see `set_homepage_name()` or to override
--                 elements of a registered page, see , `override_page()`.
sfinv = {
	pages = {},
	pages_unordered = {},
	contexts = {},
	enabled = true
}

local homepage_name = "sfinv:crafting"
-- per player homepages
local homepage_names = {}
-- list of page names or callbacks in decreasing priority,
-- callbacks shal return a name of a page or nil to 'miss a turn'
local homepage_overrides = {}


-- Adds an override for player's homepages.
-- `override`: must be a name of a registered page or a callback,
--             Callbacks will be called with the player as parameter.
--             That way a mod has control per player or for all players.
-- The override added last gets highest priority, but if it is a callback it
-- may leave the decision to the next one, by returning nil.
-- Callbacks must return the name of a registered page or nil. Invalid return
-- values will be treated like nil.
function sfinv.add_homepage_override(override)
    local t = type(override)
    if t ~= "string" and t ~= "function" then
        -- error handling to support modding
        local str = (t == "string") and override or ""
        core.log("warning", "sfinv.remove_homepage_override(): cannot add an"
                  .. " override of type " .. t .. " " .. str)
        return
    end
    table.insert(homepage_overrides, 1, override)
end

-- Removes an override for the current homepage
function sfinv.remove_homepage_override(override)
    local t = type(override)
    if t ~= "string" and t ~= "function" then
        return
    end
    for idx, val in ipairs(homepage_overrides) do
        if val == override then
            table.remove(homepage_overrides, idx)
            return
        end
    end
    -- error handling to support modding
    local str = (t == "string") and override or ""
    core.log("warning", "sfinv.remove_homepage_override(): could not find"
             .. " given override of type " .. t .. " " .. str)
end

-- Sets the name of the page to be set initially when a player joins as well as
-- after set_context() was called with a nil context.
-- `new_name`: name of the page to set for `player`
-- WARNING: Make sure to not set a page as homepage before every prerequisites
--          of that page are set up for `player`. E.g. if some player-specific
--          pre-reqs are initialized in a callback registered with
--          register_on_joinplayer() then you could set the page safely in the
--          same function or any time later. Otherwise you might see crashes
--          due to sfinv setting the page too early.
function sfinv.set_homepage_name(player, new_name)
    local name = player:get_player_name()
    if name then
        homepage_names[name] = new_name
    else
        homepage_names[name] = nil
    end
end

-- default tab_order will be order of registration
local tab_order = {}

function sfinv.register_page(name, def)
	assert(name, "Invalid sfinv page. Requires a name")
	assert(def, "Invalid sfinv page. Requires a def[inition] table")
	assert(def.get, "Invalid sfinv page. Def requires a get function.")
	assert(not sfinv.pages[name], "Attempt to register already registered sfinv page " .. dump(name))

	sfinv.pages[name] = def
	def.name = name
    table.insert(tab_order, name)
	table.insert(sfinv.pages_unordered, def)
end

function sfinv.override_page(name, def)
	assert(name, "Invalid sfinv page override. Requires a name")
	assert(def, "Invalid sfinv page override. Requires a def[inition] table")
	local page = sfinv.pages[name]
	assert(page, "Attempt to override sfinv page " .. dump(name) .. " which does not exist.")
	for key, value in pairs(def) do
		page[key] = value
	end
end

function sfinv.remove_page(pagename)
    -- remove page from sfinv.pages_unordered array
    local def = sfinv.pages[pagename]
    local removed = false
    for i = 1, #sfinv.pages_unordered do
        if not removed then
            if sfinv.pages_unordered[i] == def then
                removed = true
            end
        end
        if removed == true then
            sfinv.pages_unordered[i] = sfinv.pages_unordered[i + 1]
        end
    end
    -- remove page from tab_order array
    removed = false
    for j = 1, #tab_order do
        if not removed then
            if tab_order[j] == pagename then
                removed = true
            end
        end
        if removed == true then
            tab_order[j] = tab_order[j + 1]
        end
    end
    -- remove page from sfinv.pages
    sfinv.pages[pagename] = nil
end

function sfinv.get_nav_fs(player, context, nav, current_idx)
	-- Only show tabs if there is more than one page
	if #nav > 1 then
		return "tabheader[0,0;sfinv_nav_tabs;" .. table.concat(nav, ",") ..
				";" .. current_idx .. ";true;false]"
	else
		return ""
	end
end

local theme_inv = [[
        image[0,5.2;1,1;gui_hb_bg.png]
        image[1,5.2;1,1;gui_hb_bg.png]
        image[2,5.2;1,1;gui_hb_bg.png]
        image[3,5.2;1,1;gui_hb_bg.png]
        image[4,5.2;1,1;gui_hb_bg.png]
        image[5,5.2;1,1;gui_hb_bg.png]
        image[6,5.2;1,1;gui_hb_bg.png]
        image[7,5.2;1,1;gui_hb_bg.png]
        list[current_player;main;0,5.2;8,1;]
        list[current_player;main;0,6.35;8,3;8]
    ]]


function sfinv.make_formspec(player, context, content, show_inv, size)
	local tmp = {
		size or "size[8,9.1]",
		sfinv.get_nav_fs(player, context, context.nav_titles, context.nav_idx),
		show_inv and theme_inv or "",
		content
	}
	return table.concat(tmp, "")
end

-- Exile added part ------------------------------------------------------------
local function add_setting_button()
    --[[ with background
    return "style[player_settings;border=false; noclip =true; bgimg=gui_formbg.png;bgimg_middle=10]"..
    --"style[player_settings:focused;border=true ]"..
    "image_button[11.25,-0.08;1.05,1.05;gear.png;player_settings;]"
    ]]

    -- without background
    return "style[player_settings;border=false; noclip =true]"..
	-- on the right
    "image_button[11.5,-0.75;0.7,0.7;gear2.png;player_settings;]"
	-- on the left
    --"image_button[-1,-0.7;0.7,0.7;gear2.png;player_settings;]"
end

local inv_y = 7.2

local exile_theme_inv = {
		"list[current_player;main;0.8,".. inv_y .. ";8,1;]",
		"list[current_player;main;0.8,".. inv_y + 1.25 .. ";8,3;8]"
	}

function sfinv.make_formspec_for_exile(player, context, content, show_inv)
	local tmp = {
        "formspec_version[5]",
		--"size[11.2,10.5]",
        "size[11.4,10]",
		"position[0.5,0.5]",
		sfinv.get_nav_fs(player, context, context.nav_titles, context.nav_idx),
        add_setting_button(),
        show_inv and table.concat(exile_theme_inv,"") or "",
		content
	}
	return table.concat(tmp, "")
end

--------------------------------------------------------------------------------

function sfinv.get_homepage_name(player)
    for _, value in pairs(homepage_overrides) do
        local page_name = value
        if type(value) == "function" then
            page_name = value(player)
        end
        -- is this a name of a known page?
        if page_name and sfinv.pages[page_name] then
            return page_name
        end
    end
    local page_name = homepage_names[player:get_player_name()]
    if sfinv.pages[page_name] then return page_name end

    return homepage_name
end

-- in order to be able to set custom tab order
function sfinv.set_tabs(tab_list)
    local pages_left = {}
    -- save original tab order to keep missed pages in original order
    for i, page_name in ipairs(tab_order) do
        pages_left[page_name] = i
    end
    tab_order = {}
    for _, page_name in ipairs(tab_list) do
        -- if page is registered
        if sfinv.pages[page_name] then
            table.insert(tab_order, page_name)
            pages_left[page_name] = nil
        else
            core.log("in sfinv.set_tabs: we are trying to register a tab with undefined page")
        end
    end
    local missed_pages = {}
    for page_name, _ in pairs(pages_left) do
        table.insert(missed_pages, page_name)
    end
    -- sort to return missed_pages to original tab order
    table.sort(missed_pages, function(l, r)
        return pages_left[l] < pages_left[r]
    end)
    if #missed_pages > 0 then
        core.log("info", "sfinv.set_tabs: appending missed pages: "..dump(missed_pages))
    end
    for _, page_name in ipairs(missed_pages) do
        table.insert(tab_order, page_name)
    end
end

function sfinv.get_formspec(player, context)
	-- Generate navigation tabs
	local nav = {}
	local nav_ids = {}
	local current_idx = 1
    for i, p_name in ipairs (tab_order) do
        local pdef = sfinv.pages[p_name]
        if not pdef then
            core.log("warning","page " .. p_name
            .. " is not registered yet, returning empty formspec")
            return ""
        end
        if not pdef.is_in_nav or pdef:is_in_nav(player, context) then
			nav[#nav + 1] = pdef.title
			nav_ids[#nav_ids + 1] = p_name
			if p_name == context.page then
				current_idx = #nav_ids
			end
		end
    end
	context.nav = nav_ids
	context.nav_titles = nav
	context.nav_idx = current_idx

	-- Generate formspec
	local page = sfinv.pages[context.page] or sfinv.pages["404"]
	if page then
		return page:get(player, context)
	else
		local old_page = context.page
		local home_page = sfinv.get_homepage_name(player)

		if old_page == home_page then
			minetest.log("error", "[sfinv] Couldn't find " .. dump(old_page) ..
					", which is also the old page")

			return ""
		end

		context.page = home_page
		assert(sfinv.pages[context.page], "[sfinv] Invalid homepage")
		minetest.log("warning", "[sfinv] Couldn't find " .. dump(old_page) ..
				" so switching to homepage")

		return sfinv.get_formspec(player, context)
	end
end

function sfinv.get_or_create_context(player)
	local name = player:get_player_name()
	local context = sfinv.contexts[name]
	if not context then
		context = {
			page = sfinv.get_homepage_name(player)
		}
		sfinv.contexts[name] = context
	end
	return context -- return reference to sfinv.contexts[name]
end

-- Sets the current context of `player` to `context`.
-- - Unless further changes follow, this will make `context.page` the next page
--   to be set as the current inventory formspec when
--   sfinv.set_player_inventory_formspec() is called without parameter
--   `context`. Basically this means you are proposing a certain page to be the
--   next one to appear when a player opens the inventory GUI, but it will only
--   appear if another part of the code decides to actually set 'whatever was
--   proposed' to become the current page.
--   `context` including any custom elements in it will be available in the
--   page's on_player_receive_fields() through its 2nd parameter `context`.
-- Another possible use case of this function is to clear the player's current
--   context by passing nil as `context` followed by calling
--   `sfinv.set_player_inventory_formspec()` also with nil as `context` to
--   create a new context based on the return value of `get_homepage_name()`.
--   However, the same is achieved simply by `set_page(player)`.
-- WARNING This function does not check anything. The caller is responsible for
--         providing the name of a registered page in `context.page`, otherwise
--         a fallback will be used instead.
function sfinv.set_context(player, context)
	sfinv.contexts[player:get_player_name()] = context
end

-- Sets context.page as the current inventory formspec or updates its content.
-- If `context` is omitted (or nil) the current page is set, i.e. it is updated
-- to what its get() callback returns.
-- If `context` is not nil, `context.page` must be the name of a registered
-- page.
function sfinv.set_player_inventory_formspec(player, context)
	local fs = sfinv.get_formspec(player,
			context or sfinv.get_or_create_context(player))
	player:set_inventory_formspec(fs)
end

-- Sets the current inventory page by name or sets the player's homepage.
-- `player`: the player to set the page for
-- `pagename`: page to set; if nil the player's homepage will be set
function sfinv.set_page(player, pagename)
    pagename = pagename or sfinv.get_homepage_name(player)

    -- get reference to sfinv.context[player name]
	local context = sfinv.get_or_create_context(player)
	local oldpage = sfinv.pages[context.page]
	if oldpage and oldpage.on_leave then
		oldpage:on_leave(player, context)
	end
	context.page = pagename -- updates sfinv.context[player name], YES THIS LINE!!!
	local page = sfinv.pages[pagename]
	if page.on_enter then
		page:on_enter(player, context)
	end
	-- pass the reference to sfinv.context[player name] to actually set the page
	sfinv.set_player_inventory_formspec(player, context)
end

-- Returns the name of the page currently set for `player`.
function sfinv.get_page(player)
	local context = sfinv.contexts[player:get_player_name()]
	return context and context.page or sfinv.get_homepage_name(player)
end

minetest.register_on_joinplayer(function(player)
	if sfinv.enabled then
		sfinv.set_player_inventory_formspec(player)
	end
end)

minetest.register_on_leaveplayer(function(player)
	sfinv.contexts[player:get_player_name()] = nil
end)

minetest.register_on_player_receive_fields(function(player, formname, fields)
	if formname ~= "" or not sfinv.enabled then
		return false
	end

	-- Get Context
	local name = player:get_player_name()
	local context = sfinv.contexts[name]
	if not context then
		sfinv.set_player_inventory_formspec(player)
		return false
	end

	-- Was a tab selected?
	if fields.sfinv_nav_tabs and context.nav then
		local tid = tonumber(fields.sfinv_nav_tabs)
		if tid and tid > 0 then
			local id = context.nav[tid]
			local page = sfinv.pages[id]
			if id and page then
                -- little hack to pass as parameter the info that inv is open
                context.open_inv = ""
				sfinv.set_page(player, id)
                context.open_inv = nil -- remove once set
			end
		end
	else
		-- Pass event to page
		local page = sfinv.pages[context.page]
		if page and page.on_player_receive_fields then
			return page:on_player_receive_fields(player, context, fields)
		end
	end
end)
