chivalry-giantslayers
=====================

Everyone starts at 60% normal size. 

Every kills grows you, and your health, by 15%. 


Feel free to reuse this mod or any parts of it. Just rename any derivative mods to something else to avoid confusion.

=================

In the Steam Workshop: http://steamcommunity.com/sharedfiles/filedetails/?id=226726898

The "Creating the Giant Slayers mod" tutorial: https://tornbannerjira.atlassian.net/wiki/pages/viewpage.action?pageId=20054366

=================

Currently this only supports FFA, and there are some bugs (players are so small to start with that they 'swim' in Cistern; on maps with landscape you'll occasionally clip through it when you kill someone unless you jump first). There are plans to improve it now that we've seen how entertaining this thing is, though. 

=================i

Using the .cmwsdk file from the Workshop, or after compiling and cooking this mod locally (setting the "modname" to "giantslayers"):


Start a server with ?modname=giantslayers on the command line (appended to the map). For example:

UDK.exe aoctd-frigid_p?modname=giantslayers ...

=================

You can specify the mod you'd like to use in the maplist as well (in PCServer-UDKGame.ini), allowing you to switch between mods if you want. For example: 

Maplist=aoctd-frigid_p?modname=giantslayers 

Maplist=aoctd-moor_p?modname=someothermod 

================= 

If you want to play offline, just use the 'open' console command, again appending ?modname

open aocffa-arena3_p?modname=giantslayers
