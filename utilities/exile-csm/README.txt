Exile Controls Client-Side Mod
Written by Mantar

Licensed under the GPL v3 or any later version (c) 2024

This mod reads controls from the client and notifies the Exile
server of relevant keypresses, so as to mitigate lag on servers.

Setup:

To enable CSMs, you will need to add "enable_client_modding = true"
to your minetest.conf if you haven't already.

Install this under $HOME/.minetest/clientmods/ or the relevant folder,
and add:

load_mod_exile_csm = true

to your $HOME/.minetest/clientmods/mods.conf to activate it.

