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
	"", 		-- node description 
	"Owner",	-- Node Owner
	"Location", 	-- Transporter Location
	"Destination",  -- Transporter Destination
	"Description",  -- Trigger Description
	"Bundle",	-- Dye Bundles
	"Bed",		-- Beds
}
-- Split infotext line into keyed or unkeyed list. 
function minimal.infotext_parse_key(line,keyed_list,unkeyed_list)
	local key = line:find(':',1,true)
	if not key then
		table.insert(unkeyed_list,line)
	else
		--remove ':' from key
		key = str:sub(1, key - 1)
		keyed_list[key] = line
	end
end

-- Get infotext from meta data and split it into lines.
-- sort it into keyed and unkeyed lists and return the lists
function minimal.infotext_parse_infotext(meta)
	local keyed = {} 
	local unkeyed = {} -- lines without keys
	local infotext_string = meta:get_string("infotext")
	if infotext_string ~= '' then
		for line in infotext_string:gmatch("([^%s]+)") do
			minimal.infotext_parse_keys(line,keyed,unkeyed)
		end
	end
print ("old_lines: "..dump(lines))
print ("unkeyed_lines:"..dump(unkeyed))
	return lines,unkeyed
end

-- Accept a string with a single infotext line or a table of multiple strings
-- split the lines into keyed and unkeyed lists provided.
function minimal.infotext_parse_new(lines,keyed, unkeyed)
	-- passed a string, convert it to the expected table
	if lines and type(lines) == 'string' then
		local line=lines
		lines={}
		table.insert(lines,line)
	end

	for _,line in ipairs(lines) do
		minimal.infotext_parse_key(line,keyed,unkeyed)
	end
	return lines
end

function table.removekey(table, key)
	local value = table[key]
	table[key] = nil
	return value
end
-- Append keys to the output removing them from the append_list, and optionally a second list
-- Intended for 2 passes, one with the new infotext lines and the old lines from meta data as
-- the remove list. The second pass is with only the old lines and no additional remove lines.
function minimal.infotext_append_keys(output_list, append_list, remove_list)
	-- Any more keys in new_lines
	if append_list and #append_lines > 0 then
		for key,line in pairs(append_list) do
			local new_line = table.removekey(append_list,key)
			if remove_list then
				table.removekey(remove_list,key)
			end
			table.insert(output_list,new_line)
		end
	end
end


-- Main funtion called from other modules.
-- Takes the pos of the node being modifide, in string or pos object form and
-- a single line of text or a list of text lines to add/replace.
-- Lines should ideally be keyed as follows:

-- key: Infotext line to add/replace

-- New keys replace old keys.
-- If called with no lines, and no existing info text, The description of the node and 
-- name of the owner will be added.  Any info text added will also include these lines
-- using data from the node's description and owner meta data.

function minimal.set_infotext(pos,add_lines)
	if type(pos) == "string" then
		pos = minetest.string_to_pos(pos)
	end
	local meta = minetest.get_meta(pos)
	local old_lines,unkeyed = minimal.infotext_parse_infotext(meta)
	
	local output_lines={}
	
	-- Line 1 is always the item description
	local desc = minetest.registered_nodes[minetest.get_node(pos).name].description
	output_lines[1] = desc
	-- Line 2 is always Owner if set
	local owner = meta:get_string('owner')
	if owner then
		output_lines[2] = S("Owner: ") .. owner
	end
	
	local new_lines = minimal.infotext_parse_new(add_lines,unkeyed)
print ("Before Ordered Lines")
print ("old_lines"..dump(old_lines))
print ("new_lines"..dump(new_lines))
print ("output_lines: "..dump(output_lines))
	-- Use fixed_order list to find output_lines
	for i, ordered_key in ipairs(fixed_order) do 
		if i > 2 then  -- First 2 lines are done already
			local old_line=table.removekey(old_lines, old_keys[ordered_key]);
			local new_line=table.removekey(new_lines, ordered_key);
			if new_line then
				table.insert(output_lines,new_line)
			elseif old_line then
				table.insert(output_lines,old_line)
			end
		end
	end
print ("After Ordered Lines")
print ("old_lines"..dump(old_lines))
print ("new_lines"..dump(new_lines))
print ("output_lines: "..dump(output_lines))
	minimal.infotext_append_keys(output_lines,new_lines,old_lines)
print ("After Append new Keys")
print ("old_lines"..dump(old_lines))
print ("new_lines"..dump(new_lines))
print ("output_lines: "..dump(output_lines))
	minimal.infotext_append_keys(output_lines,old_lines)
print ("After Append old Keys")
print ("old_lines"..dump(old_lines))
print ("new_lines"..dump(new_lines))
print ("output_lines: "..dump(output_lines))
	-- append unkeyed lines
	if #unkeyed > 0 then
		for _, line in ipairs(unkeyed) do
			-- Exclude the node description from unkeyed lines
			if line and line ~= output_lines[1] then
				table.append(output_lines, line)
			end
		end
	end
print ("After Append unkeyed lines")
print ("old_lines"..dump(old_lines))
print ("new_lines"..dump(new_lines))
print ("unkeyed: "..dump(unkeyed))
print ("output_lines: "..dump(output_lines))

	-- combine lines into string and set infotext
	local text="";
	for _,line in ipairs(new_lines) do
		text = text .. line .. "\n"
	end
	text = text:sub(1, -2) -- remove last \n
	meta:set_string("infotext",text)
	return text
end


