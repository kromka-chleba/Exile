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
local S=minimal.S()

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
			key = str:sub(1, key - 1)
		end
		keys[key] = i
		i = i + 1
	end
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

	-- passwd a string, convert it to the expected table
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
	-- find old entries we're replacing
	for key,index in pairs(old_keys) do
		-- ignore first 2 lines
		if index > 2 then
			if lines and lines[key] then
				-- key found in passed values so replace it using old index value
				new_lines[index] = lines[index]
				lines[key] = nil -- clear out passed lines processed
			else
				new_lines[index] = old_lines[index]
			end
			c = c + 1
			old_lines[index] = nil  -- clear out old lines processed
		end
	end
	
	-- append remaining entries from old_lines
	for _, str in ipairs(old_lines) do
		if str then
			mew_lines[c] = str
			c = c + 1
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


