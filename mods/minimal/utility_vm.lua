minimal = minimal

function minimal.vmanip_subregion(pos1, pos2, p1, p2)
   -- Creates parameters to a for loop that will cover an x/y/z subregion of a
   --  voxelmanip's flat array. Parameters pos1/2 are the subregion you wish to
   --  work with, while p1/2 are the full extent of the voxelmanip area

   -- For example:
   --  local VM_area1, VM_area2 = VoxelManip:read_from_map(MyPos1, MyPos2)
   --  retv = vmanip(subregion(MyPos1, MyPos2, VM_area1, VM_area2)
   --  for z = retv.zstart, retv.zstop, retv.zstep do
   --    for y ... -- (as above)
   --      for x ...
   --        local index = x+y+z ; data[index] = my_node_cid
   --

   -- First we get dimensions for the VM array
   local xl = p2.x - p1.x + 1 -- X length of the whole VM area, count from 1
   local yl = p2.y - p1.y + 1 -- Y length
   local zl = p2.z - p1.z + 1 -- Z length
   local zstep = xl*yl local ystep = xl local xstep = 1
   local size = zstep*zl -- how big the flat array is
   -- now we figure offsets for pos1 vs p1, pos2 vs p2, so we can shave them off
   local xs = pos1.x - p1.x local xe = pos2.x - p2.x -- x start / end
   local ys = (pos1.y - p1.y) * xl -- y start / end
   local ye = (pos2.y - p2.y) * xl -- distance from ends of a z chunk
   local zs = (pos1.z - p1.z) * yl*xl -- z start/end
   local ze = (pos2.z - p2.z) * yl*xl-- distance from the ends of the vm array
   return { zstart = zs, zstop = size+ze-zstep, zstep = zstep,
	     -- we subtract zstep to reduce the end by 1 or else we'll run over
	    ystart = ys, ystop = zstep+ye-ystep, ystep = ystep,
	    xstart = xs, xstop = xl+xe-xstep, xstep = xstep
   }
end
