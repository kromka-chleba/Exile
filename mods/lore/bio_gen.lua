----------------------------------------------------------
--BIO GEN
--[[
	Biography.

	Who is the character for this life?
	Displayed on Char_tab.'

	Gives sense of character.

	Each life is a chance to behave different, try new strategies, methods, modes of being.
	The traits suggested are a primer to do things different than your normal patterns.

	"[Outgoing] and [diligent],
	[Bob] had lived a [miserable] life,
	until one day [he][picked a fight with the wrong people].... "
]]
local random = math.random
local S = lore.S
local NS = function(s) return s end
----------------------------------------------------------
local gender = {
	male   = NS("he"),
	female = NS("she")
}
-- Big Five
-- (Try to make sure these are different from virtues!)
local personality = {
  -- openness
  NS("Conventional"),
  NS("Unconventional"),
  NS("Practical"),
  NS("Imaginative"),
  NS("Unadventurous"),
  NS("Adventurous"),
  NS("Traditional"),
  NS("Rebellious"),
  -- conscientiousness
  NS("Organized"),
  NS("Disorganized"),
  NS("Goal-driven"),
  NS("Impulsive"),
  NS("Dutiful"),
  NS("Careless"),
  NS("Precise"),
  NS("Slapdash"),
  -- extroversion
  NS("Shy"),
  NS("Gregarious"),
  NS("Quiet"),
  NS("Outgoing"),
  NS("Withdrawn"),
  NS("Sociable"),
  NS("Reserved"),
  NS("Expressive"),
  -- agreeableness
  NS("Pleasant"),
  NS("Argumentative"),
  NS("Good-natured"),
  NS("Critical"),
  NS("Soft-hearted"),
  NS("Suspicious"),
  NS("Gullible"),
  NS("Cynical"),
  -- neuroticism
  NS("Calm"),
  NS("Neurotic"),
  NS("Steady"),
  NS("Unstable"),
  NS("Self-satisfied"),
  NS("Moody"),
  NS("Complacent"),
  NS("Paranoid")
}
-- Miscellaneous Virtues
local virtue = {
  NS("courageous"),
  NS("temperate"),
  NS("charitable"),
  NS("extravagant"),
  NS("magnanimous"),
  NS("patient"),
  NS("honest"),
  NS("witty"),
  NS("friendly"),
  NS("modest"),
  NS("just"),
  NS("ambitious"),
  NS("assertive"),
  NS("benevolent"),
  NS("brave"),
  NS("caring"),
  NS("chaste"),
  NS("cautious"),
  NS("fastidious"),
  NS("committed"),
  NS("compassionate"),
  NS("confident"),
  NS("considerate"),
  NS("contented"),
  NS("cooperative"),
  NS("courteous"),
  NS("creative"),
  NS("curious"),
  NS("defiant"),
  NS("dependable"),
  NS("determined"),
  NS("devoted"),
  NS("diligent"),
  NS("discerning"),
  NS("discrete"),
  NS("disciplined"),
  NS("eloquent"),
  NS("empathic"),
  NS("enthusiastic"),
  NS("faithful"),
  NS("flexible"),
  NS("focused"),
  NS("tolerant"),
  NS("forgiving"),
  NS("strong"),
  NS("frugal"),
  NS("gentle"),
  NS("graceful"),
  NS("grateful"),
  NS("helpful"),
  NS("honorable"),
  NS("hopeful"),
  NS("humble"),
  NS("comical"),
  NS("idealistic"),
  NS("virtuous"),
  NS("impartial"),
  NS("industrious"),
  NS("innocent"),
  NS("joyful"),
  NS("kind"),
  NS("knowledgeable"),
  NS("loving"),
  NS("loyal"),
  NS("noble"),
  NS("dignified"),
  NS("merciful"),
  NS("moderate"),
  NS("peaceful"),
  NS("persistent"),
  NS("prudent"),
  NS("purposeful"),
  NS("reliable"),
  NS("resolute"),
  NS("resourceful"),
  NS("respectful"),
  NS("responsible"),
  NS("reverent"),
  NS("righteous"),
  NS("selfless"),
  NS("sensitive"),
  NS("contemplative"),
  NS("sincere"),
  NS("sober"),
  NS("spontaneous"),
  NS("steadfast"),
  NS("tactful"),
  NS("thrifty"),
  NS("tough"),
  NS("tranquil"),
  NS("trusting"),
  NS("trustworthy"),
  NS("understanding"),
  NS("vigorous"),
  NS("wise"),
  NS("zealous")
}
-- State of former life:
-- (Ought to contrast with the world of Exile.)
local life = {
  -- Favorable
  NS("a good"),
  NS("a happy"),
  NS("a pleasant"),
  NS("an enjoyable"),
  -- Drab
  NS("a boring"),
  NS("an uneventful"),
  NS("a mediocre"),
  NS("a dull"),
  NS("a humdrum"),
  -- Easy
  NS("a comfortable"),
  NS("a satisfied"),
  NS("a soft"),
  NS("an easy"),
  -- Nominal
  NS("a normal"),
  NS("an average"),
  NS("an unremarkable"),
  -- Diminutive
  NS("a restricted"),
  NS("a narrow-horizoned"),
  NS("a homely"),
  NS("a constricted"),
  -- Grievous
  NS("a frustrated"),
  NS("an empty"),
  NS("an unfulfilling"),
  NS("a sorrowful"),
  NS("a mournful"),
  NS("a long-suffering"),
  -- Toiling
  NS("an overburdened"),
  NS("a hardworking"),
  NS("a slave-like"),
  -- Social
  NS("a family centred"),
  NS("a communal"),
  NS("a self-centred"),
  NS("a selfless"),
  NS("a solitary"),
  NS("a low-born"),
  NS("an aristocratic"),
  -- Moral
  NS("a well respected"),
  NS("an upstanding"),
  NS("a patriotic"),
  NS("an honorable"),
  -- Wasted
  NS("a dissipated"),
  NS("a dissolute"),
  NS("a slothful"),
  NS("an indulgent"),
  NS("a misspent"),
  -- Aberrant
  NS("an eccentric"),
  NS("an oddball"),
  NS("a strange")
}
-- What went wrong:
local woe = {
  -- Bad Business
  NS("made a bad bargain"),
  NS("made a deal with the wrong people"),
  NS("sold out and got swindled"),
  NS("was made an offer too good to be true"),
  NS("saw a fantastic opportunity"),
  NS("took a gamble"),
  NS("found a new way to make a living"),
  -- Emotion
  NS("lost all hope"),
  NS("fell into despair"),
  NS("discovered a great passion"),
  NS("found a source of great joy"),
  NS("was provoked to anger"),
  NS("lashed out"),
  NS("snapped"),
  NS("couldn't take it anymore"),
  NS("decided love was dead"),
  NS("felt like the world didn't care"),
  NS("was disgusted by life"),
  NS("became obsessed"),
  -- Fight the Power
  NS("stood up for the truth"),
  NS("spoke truth to power"),
  NS("took a stand"),
  NS("picked a fight with the wrong people"),
  NS("raged against the machine"),
  NS("fought for justice"),
  NS("put everything toward the cause"),
  NS("rose up against the oppressor"),
  -- Wrong Type of Person/Corruption
  NS("was persecuted by the intolerant"),
  NS("refused to conform"),
  NS("refused to hide anymore"),
  NS("chose to live differently"),
  NS("saw things others did not see"),
  -- Life Change
  NS("decided not live that way anymore"),
  NS("thought life needed shaking up"),
  NS("made a few minor changes"),
  NS("had an epiphany"),
  NS("took up a new hobby"),
  -- Crime
  NS("got in too deep"),
  NS("chose the wrong path"),
  NS("thought no one would notice"),
  NS("got caught"),
  NS("got snitched on"),
  NS("bungled a sure thing"),
  -- Poverty
  NS("fell on hard times"),
  NS("did what needed to be done"),
  NS("did what it took to feed the family"),
  -- Politics
  NS("picked the losing side"),
  NS("took a chance to grab power"),
  NS("ended up on the wrong side of history"),
  NS("offended a powerful man"),
  NS("offended a powerful woman"),
  NS("provoked the jealousy a rival"),
  -- Random Acts
  NS("was just passing by, when"),
  NS("had an accident"),
  NS("was mistaken for someone else"),
  NS("was imprisoned on false charges"),
  NS("got caught up in someone else's mess"),
  NS("witnessed what was supposed to be a secret"),
  -- One Stupid Mistake
  NS("made one bad decision"),
  NS("said one wrong thing"),
  NS("gave in to temptation"),
  NS("had a momentary lapse of judgement"),
  NS("started something too big"),
  NS("lost control"),
  NS("followed bad advice"),
  NS("had too much to drink"),
  NS("learned the truth too late"),
  NS("committed a simple indiscretion"),
  NS("had a great idea"),
  NS("misjudged the situation entirely"),
  -- Romance/Family
  NS("fell in love"),
  NS("had an affair"),
  NS("gave up everything for love"),
  NS("had a son"),
  NS("had a daughter"),
  NS("discovered a long-lost relative"),
  NS("got mixed up in a love triangle"),
  -- Weird
  NS("got involved with a travelling magician"),
  NS("met a man with two heads"),
  NS("found a bird that could predict the future"),
  NS("ate some odd beans"),
  NS("tried to learn the flute"),
  NS("was given a secret map"),
  NS("discovered a secret chamber"),
  NS("saw a ghost"),
  NS("received a vision from the other side"),
  NS("had a dream that explained everything"),
  NS("built a perpetual-motion machine"),
  NS("learned the meaning of life")
}
lore.generate_bio = function(player)
	local text = ""

	local meta = player:get_meta()
	local gend = player_api.get_gender(player)

	local persona   = personality[random(#personality)]
	local virt      = virtue[random(#virtue)]
	local your_name = meta:get_string("char_name")
	local lif       = life[random(#life)]
	local your_woe  = woe[random(#woe)]

	text =
		-- "\n "..persona.." and "..virt..","..
		-- "\n "..your_name.." had lived "..lif.." life,"..
		-- "\n until one day "..gender[gend].." "..your_woe.."...."
    S("\n @1 and @2,"..
		  "\n @3 had lived @4 life,"..
		  "\n until one day @5 @6....",
      S(persona), S(virt), your_name, S(lif), S(gender[gend]), S(your_woe))
		meta:set_string("bio", text)
	return text
end
