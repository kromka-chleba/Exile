Exile mod: Mapchunk shepherd
=============================

Tracks mapchunks players visited and stores info about them.

Authors of source code
----------------------
Jan Wielkiewicz (GPLv3)

## General idea

The Mapchunk Shepherd is a system responsible for:
* Tracking player movement to obtain information about the map
* Assigning labels to pieces of the map
* Modifying/updating specific pieces of the map

## Features
* Uses the Voxel Manipulator so should be pretty fast
* Dynamic modification of the map
* Workers and scanners can be unregistered and registered on the fly (unlike ABMs and LBMs)
* Scan once, modify multiple times
* Unlike ABMs, it can modify mapchunks far away from the player because it uses "loaded" chunks
* Unlike ABMs and LBMs, processes/scans only specific chunks (with specific labels)

## Terminology
* Mapblock:
Usually a 16x16x16 cubic piece of the map.

* Chunk size:
Number of mapblocks one mapchunk has along each of its axes, by default it is 5.

* Mapchunk:
A cubic piece of map consisting of mapblocks. Mapchunk has a side of N mapblocks where N is equal to chunk size.
By default a mapchunk has a side of 80 (16 * 5).

* Mapchunk offset:
Is defined as -16 * math.floor(chunk_size / 2) so by default -32.
It is the number of nodes by which each mapchunk was shifted relatively to x = 0, y = 0, z = 0 position of the map.
This means the beginning of the first chunk is not at x = 0, y = 0, z = 0 but at x = -32, y = -32, z = -32 (when chunk_size = 5).
Apparently Minetest does it this way so players spawn at the center of a mapchunk and not at the edge.

* Player tracker:
The facility responsible for tracking each player and loading neighboring mapchunks into the system.

* Neighborhood:
A cuboid space around a player consisting of whole mapchunks including the mapchunk each player is in.

* Label:
A string assigned to a mapchunk with a corresponding binary ID.
It describes the contents of the chunk, e.g. "has_trees" or "has_diamonds".
It is stored in Minetest's mod storage, saved on the disk separately for each world.
Currently the Shepherd supports only 48 labels because it stores them in a 48-bit int.
Storing labels in the int saves space.

* Scanner:
A Voxel Manipulator that scans a mapchunk for certain nodes and assigns or removes labels accordingly.
For example a scanner could search for trees and assign the "has_trees" label.

* Worker:
A Voxel Manipulator that modifies previously scanned mapchunks.
For example it can replace trees on mapchunks having the "has_trees" label with cotton candy trees and replace the label with "has_candy_trees".

* Tracked mapchunk:
A mapchunk that was found in the neighborhood of a player and had been assigned the "chunk_tracked" label.

* Mapchunk hash:
Is the hashed position of the minimal position of a mapchunk that serves as the mapchunk's ID.
It is obtained using minetest.hash_node_position(pos_min).

* Scan queue:
Is the list of mapchunks (mapchunk hashes) that wait for being scanned.
The player tracker adds tracked mapchunks without the "scanned" label into the queue.
If scanning was successful, the hash is removed from the queue and the mapchunk is assigned the "scanned" label.

* Work queue:
Is the list of mapchunks (mapchunk hashes) that wait for being processed.
The player tracker adds scanned chunks (having "chunk_tracked" and "scanned" labels) into the work queue.
Extra "Needed labels" can be defined to restrict workers to only specific chunks and avoid processing them twice.
For example a worker replacing spring soil with winter soil will only pick up chunks having the "has_spring_soil"
label and replace the label with "has_winter_soil".
Workers replace nodes on these mapchunks and assign specific labels, then the hash is removed from the queue.
