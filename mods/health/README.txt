Exile mod: Health
=============================
Adds player health effects e.g. hunger, thirst, fatigue, hypothermia, poisoning, disease



Consummable items:
-----------------
HEALTH.use_item(itemstack, user, food_table)

food_table can either be nil (will read from HEALTH.food_table) or table
food_table = {hp=0,th=0,hu=0,en=0,temp=0,replace_item=""}
not all variables have to be specified

call from _on_use_item
e.g. adds 5 food, minus 10 energy.
_on_use_item = function(user, itemstack, pointed_thing)
  return HEALTH.use_item(itemstack, user, {hu=5,en=-10})
end,




Authors of source code
----------------------
Dokimi (GPLv3)
Mantar
TubberPupperHusker (Exile Licensing)



Authors of media
-----------------
Health_alert http://soundbible.com/1669-Robot-Blip-2.html, Attribution 3.0, Marianne Gagnon
Health_vomit http://soundbible.com/173-Puke-Vomit-Ralph.html Attribution 3.0 Mike Koenig
health_hallucinate http://soundbible.com/2010-Laughter.html Attribution 3.0 Mike Koenig,
and http://soundbible.com/139-Evil-Laugh-Male-2.html Public Domain,
and http://soundbible.com/1257-Jolly-Laugh.html Attribution 3.0 Mike Koenig,
and http://soundbible.com/2191-Hyena-Laughing.html Attribution 3.0  Daniel Simion
and http://soundbible.com/366-Alien-Creatures.html Attribution 3.0 Mike Koenig,
and http://soundbible.com/863-Dolphins.html sampling Plus 1.0, acclivity
and http://soundbible.com/1071-Bouncing-Golf-Ball.html Attribution 3.0 Mike Koenig,
and http://soundbible.com/1412-Yahoo.html  sampling Plus 1.0, UncleSigmund
Health_heart http://soundbible.com/672-Beating-Heart.html Sampling Plus 1.0  greyseraohim
weather_hud_frost.png https://github.com/t-affeldt/climate CC-BY-SA, cap
weather_hud_heat.png CC-BY-SA IAmInnocent

