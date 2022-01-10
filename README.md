# Exile
Created by Dokimi
Minetest 5.4 compatible

CAUTION: Some people may find parts of this game difficult or disturbing.

## Installation
Installation from the `ContentDB` resource is preferable — just add it from the in-game menu.

If extracting manually, Exile should be in games folder like so:

	~/ > `.minetest` > `games` > `exile` > mods, menu, etc.

Since version 0.2.3, Exile requires `naturalslopeslib` (`nsl`).
If you’re installing the source from `git`, you’ll need to install `nsl` as well. 
Extract it into the `exile/mods` folder, or use `git pull --recurse submodules`, if you have cloned the repository.

## Gameplay
Challenging, at times brutal, wilderness survival with simple technology.

Use your wits to find food, water, and shelter, before succumbing to the elements,
while exploring the mysterious world, and developing your capacities to endure your exile.

Features:
- Player health effects: hypothermia, exhaustion, dehydration, hunger, disease...
- Dynamic nature: Seasonal weather, erosion, heat propagation, water flows through soil...
- Directly building: rain shelters, ovens, kilns, smelters, forges...

## World settings
The standard `mapgen` for Exile is `valleys`. Also supported is `carpathian`, 
for a somewhat more difficult and slower-paced game.
The `flat` mapgen mostly works as well, but `Merki`, and therefore the `Glow Paint` and the 
`Herbal Medicine` which requires it, will be unavailable. 
Enable these alternate `mapgen` algorithms in `game.conf` if you’d like to try it anyway.

## Gameplay Guide
Check out `doc` > `walkthrough` for a more detailed guide.

Many different strategies might work, and a large part of the fun is figuring out what does, and catastrophically does not, work.

Here are some early steps you might pass through:
1. Make basic tools. Find a suitable camp site soon before you get tired.
2. Build a bed to rest in, shelter, and maybe fire for warmth.
3. Make a kiln, and make pots. Harvest wild foods while you wait.
4. Collect water with pots, and build up a water supply.
5. Farm food, drugs, and fibre to build up supplies.
6. Explore and gather resources for more advanced tools.

You start in spring. Soon the hot dry weather of summer will arrive.
Running out of water, or getting exhausted by the heat is a real risk.
After that will come the sub-zero conditions of winter.
Starvation and freezing are hard to avoid without preparation.

Some tips and tricks:
- Beds are important. They do not simply skip the night. If you become exhausted, you get hypothermia/heat stroke. Get under shelter in a nice temperature.
- Do your crafting, organizing, planning while you rest.
- Weather: Extremes sap your energy. As with real life, walking around in a snowstorm is a bad idea!
- Temperature: Build a shelter, with a fireplace, or lots of torches. You can also go underground; caves are safe from weather.
- Water: you can safely drink cave drips (click on them). Water pots collect rain water. Some plants, and some prepared foods, can quench your thirst. You can also try to you can try to melt ice, or, if you’re desperate, dig a seepage pit in wet ground and wait for water to flow into it.
- Food: Eat things and see if you live! You can catch animals with clubs (right click on them).
- Clothing: Simple grass clothing can be woven quickly, and can be a lifesaver. Better clothes can be made by soaking bundles of the right kind of plants.
- Farming: Digging tools also can till soil (right click while wielding them). Punching depleted `Agricultural Soil` with fertilizers will restore the nutrients.
- Keep an eye on “health effects”: You may have eaten something bad, or have a terrible disease.
- Drugs: Some plants have useful medicinal effects. Be careful not to overdose, however.
- Go deep enough underground and you might find something....
- Forestry: Hardwood trees are more difficult to cut than soft. You will need better tools.
- Camping:
	- Build stairs and shelters around your base; This will save you energy and protect you from extremes.
	- You can use sticks to build a ladder, or a pole to shimmy up, to get to high places, then to descend, if you’re careful.
- Crafting:
	- Not every step in crafting can be done at a workstation. Some things need to be fired, or soaked in water, etc.
	- Ovens, kilns, and furnaces: Build them as you would for real. A fire with access to air, and a sealed chamber that gets heated up, becomes an intense thermal concentration.
- Fires: Blocks are hotter. Charcoal is hotter than wood. Fires can be temporarily extinguished by punching them while wielding sediment.
- Charcoal: Make it like you would for real, with a wood fire sealed up for limited air supply.
- Glassmaking: Sand and wood ash can be made into green glass; the ash must be soaked, dried, and roasted to make clear glass. Glass can be melted onto iron trays to make panes for real windows!
- Iron smelting: This is hard. It needs plenty of charcoal, and a space below the iron mixture for slag to drain out.

## Settings for multiplayer
The variable `time_speed` defaults to 72.
At this rate a player who logs on at 8:00 AM every day will get a change in season every 2.5 days. 
Changing `time_speed` to 60 will make days last 24 minutes and a new season every day, but he will see the seasons in reverse. At `time_speed` of 96, days last only 15 minutes, but the player might see spring (year 1) on day 1, summer (year 2) on day 2, etc.

Set `exile_hud_update` to 1 second for multiplayer servers on the Internet; a LAN server can probably handle 0.2 seconds.

## Mods for multiplayer
`Wield3d` is recommended: https://github.com/stujones11/wield3d
`Alternode` was used to add the `infotext` popups in the spawn shelter on the Land of Catastrophe server: https://github.com/AntumMT/mod-alternode

## Development
Exile is open-source software — that means it is as good as you choose to make it.
It also means development can be erratic and haphazard at times, so be patient!

Exile is currently in “Alpha”. Therefore expect that there can be bugs, missing features, performance issues, and perhaps compatibility-breaking updates. Despite this, Exile does have enough features to be a playable game and should be stable and mostly bug-free.

See the `git` repository at https://github.com/jeremyshannon/Exile/ for known bugs, and to report new ones.

## Credit
Thanks is due to all those whose mods have been adapted for use in Exile (see the respective mods’ folders for details).

Thanks also to all who have given feedback, fixes, etc. A full, up-to-date list of contributors can be found on the `GitHub` repository, under the `Insights` tab.
