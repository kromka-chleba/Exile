-- set info text using following format:
-- Node_definintion_description
-- Owner: Owner_Name
-- Line 3 Text
-- Line 4 Text
-- Line 5 Text
--
-- lines containing : use text left of : as the key
-- to make it easy to replace lines by key
--

minimal=minimal
local S=minimal.S

local fixed_order = {
	"1", 1,
	"Owner", 2,
	"TP Name", 3,
	"TP Destination", 4,
	"Dye", 5,
}

function minimal.parse_infotext(meta)
	local lines = {}
	local keys = {}
	local i = 1;
	local infotext_string = meta:get_string("infotext")
	if infotext_string == '' then
		return nil,nil
	end
	for str in infotext_string:gmatch("([^%s]+)") do
		lines[i]=str
		local key = str:find(':',1,true)
		if not key then
			key = i -- default to using the index value
		else
			-- Last version of a key found is used
			key = str:sub(1, key - 1)
		end
		keys[key] = i
		i = i + 1
	end
print ("old_lines: "..dump(lines))
print ("old_keys: "..dump(keys))
	return lines,keys
end

function minimal.set_infotext(pos,lines)
	if type(pos) == "string" then
		pos = minetest.string_to_pos(pos)
	end
	local meta = minetest.get_meta(pos)
	local old_lines,old_keys=minimal.parse_infotext(meta)
	local new_lines={}
	-- generate ownership lines if owned node
	local owner = meta:get_string('owner')
	local desc
	if owner then
		desc = minetest.registered_nodes[minetest.get_node(pos).name].description
		new_lines[1] = desc
		new_lines[2] = S("Owner: ") .. owner
	else 
		new_lines[1] = ""
		new_lines[2] = ""
	end

	local c = 3 -- line count 
print ("new_lines: "..dump(new_lines))
	-- passed a string, convert it to the expected table
	if lines and type(lines) == 'string' then
		local line=lines
		lines={}
		local key = line:find(":",1,true)
		if not key then
			key = "1" -- default to an indexed entry
		else
			key = line:sub(1,key - 1)
		end
		lines[key] = line
	end
print ("passed_lines"..dump(lines))
	-- find old entries we're replacing
	if old_keys then 
		for key,index in pairs(old_keys) do
			-- First two lines are hardcoded as description/owner
			-- Numbered keys are processed below
print (index .." - ".. key)
			if index > 2 and tonumber(key) == nil then
				local l = fixed_order[key] or index  -- override output lines with fixed_order
				if lines and lines[key] then
print ("lines["..key.."] = "..lines[key])
					new_lines[l] = lines[key]
					lines[key] = nil -- clear out passed lines processed
				else
					new_lines[l] = old_lines[index]
				end
				c = c + 1
			end
		end
print ("new_lines"..dump(new_lines))	
		-- append numbered keys from old_keys
		for key, index in ipairs(old_keys) do
			if index ~= 1 then -- index 1 hard coded to node description above
				mew_lines[c] = old_lines[index];
				c = c + 1
			end
		end
	end

	-- append remaining passed lines if any
	if lines then
		for _, str in pairs(lines) do
			if str then
				new_lines[c] = str
				c = c + 1
			end
		end
	end

	-- combine lines into string and set infotext
	local text="";
	for _,line in ipairs(new_lines) do
		text = text .. line .. "\n"
	end
	text = text:sub(1, -2) -- remove last \n
	meta:set_string("infotext",text)
	return text
end


