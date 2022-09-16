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


function print_debug(msg,old_lines,new_lines,unkeyed,output_lines)
	print (msg)
	print ("old_lines"..dump(old_lines))
	print ("new_lines"..dump(new_lines))
	print ("unkeyed: "..dump(unkeyed))
	print ("output_lines: "..dump(output_lines))
end

local fixed_order = {
--	"", 			-- node description - unkeyed but fixed as first line
	"Owner",		-- Node Owner
	"Label",		-- Custom Label
	"Creator",		-- Node Creator
	"Location", 		-- Transporter Location
	"Destination",  	-- Transporter Destination
	"Description",  	-- Trigger Description
	"Dye Test Bundle",	-- Dye Bundles
	"Bed",			-- Beds
}
-- Split infotext line into keyed or unkeyed list. 
function minimal.infotext_parse_key(line,keyed_list,unkeyed_list)
	local ikey = line:find(':',1,true)
	if ikey then
		--remove ':' from key
		local key = line:sub(1, ikey - 1)
print("<<<"..(key or "")..">>>")
		keyed_list[key] = line
	else
		table.insert(unkeyed_list,line)

	end
end

-- Get infotext from meta data and split it into lines.
-- sort it into keyed and unkeyed lists and return the lists
function minimal.infotext_parse_infotext(meta)
	local keyed = {} 
	local unkeyed = {} -- lines without keys
	local infotext_string = meta:get_string("infotext")
	if infotext_string ~= '' then
print("---------\nINFOTEXT:  "..infotext_string)
		for line in infotext_string:gmatch("[^\r\n]+") do
print ("gmatch: "..line)
			minimal.infotext_parse_key(line,keyed,unkeyed)
		end
	end
print ("old_lines: "..dump(keyed))
print ("unkeyed_lines:"..dump(unkeyed))
	return keyed,unkeyed
end

-- Accept a string with a single infotext line or a table of multiple strings
-- split the lines into keyed and unkeyed lists provided.
function minimal.infotext_parse_new(lines,unkeyed)
	local keyed = {}
	-- passed a string, convert it to the expected table
	if lines and type(lines) == 'string' then
		local line=lines
		lines={}
		if line ~= "" then
			table.insert(lines,line)
		end
	end
print ("infotext_parse_new\n----\n"..dump(lines))
	if lines and type(lines) == 'table' then
		for _,line in ipairs(lines) do
print("parse_new - line: "..line)
			minimal.infotext_parse_key(line,keyed,unkeyed)
		end
	end
	return keyed
end

function table.removekey(table, key)
	if table and type(table) == 'table' then
		local value = table[key]
		table[key] = nil
		return value
	end
	return nil
end
-- Append keys to the output removing them from the append_list, and optionally a second list
-- Intended for 2 passes, one with the new infotext lines and the old lines from meta data as
-- the remove list. The second pass is with only the old lines and no additional remove lines.
function minimal.infotext_append_keys(output_list, append_list, remove_list)
	-- Any more keys in new_lines
	if append_list and #append_list > 0 then
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

print ("***************************\n"..dump(pos))
	local meta = minetest.get_meta(pos)
	local old_lines,unkeyed = minimal.infotext_parse_infotext(meta)
	
	local output_lines={}
	
	-- Line 1 is always the item description
	local desc = minetest.registered_nodes[minetest.get_node(pos).name].description
	output_lines[1] = desc
	-- Line 2 is always Owner if set
	local owner = meta:get_string('owner')
	if owner then
		output_lines[2] = "Owner: " .. owner
	end
	
	local new_lines = minimal.infotext_parse_new(add_lines,nil, unkeyed)
print_debug("Before Ordered Lines",old_lines,new_lines,unkeyed,output_lines)
	-- Use fixed_order list to find output_lines
	for i, ordered_key in ipairs(fixed_order) do 
		local old_line=table.removekey(old_lines, ordered_key)
		local new_line=table.removekey(new_lines, ordered_key)
		if i > 1 then -- skip writing out Owner; already added above
			if new_line then
print ("NEW_LINE==="..new_line)
				table.insert(output_lines,new_line)
			elseif old_line then
print ("OLD_LINE==="..old_line)
				table.insert(output_lines,old_line)
			end
		end
	end

print_debug("After Ordered Lines",old_lines,new_lines,unkeyed,output_lines)
	minimal.infotext_append_keys(output_lines,new_lines,unkeyed,old_lines)
print_debug("After Appending new Keys",old_lines,new_lines,unkeyed,output_lines)
	minimal.infotext_append_keys(output_lines,old_lines)
print_debug("After Appending old Keys",old_lines,new_lines,unkeyed,output_lines)
	-- append unkeyed lines
	if #unkeyed > 0 then
		for _, line in ipairs(unkeyed) do
			-- Exclude the node description from unkeyed lines
			if line and line ~= output_lines[1] then
				table.insert(output_lines, line)
			end
		end
	end

print_debug("After Appending UNKEYED",old_lines,new_lines,unkeyed,output_lines)

	-- combine lines into string and set infotext
	local text="";
	for _,line in ipairs(output_lines) do
		text = text .. line .. "\n"
	end
	text = text:sub(1, -2) -- remove last \n
	meta:set_string("infotext",text)
print (text)
	return text
end


