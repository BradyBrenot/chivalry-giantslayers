chivalry-giantslayers
=====================

Everyone starts at 60% normal size.

Every kill grows you, and your health, by 15%.


Feel free to reuse this mod or any parts of it. Just rename any derivative mods to something else to avoid confusion.

=================

In the Steam Workshop: http://steamcommunity.com/sharedfiles/filedetails/?id=226726898

The "Creating the Giant Slayers mod" tutorial: https://tornbannerjira.atlassian.net/wiki/pages/viewpage.action?pageId=20054366

=================

To start a game offline, in the console, do:

open aocffa-arena3_p?modname=giantslayers
(use 'maplist ffa' to get a list of all FFA maps)


To use this on a server:

1a) Add this switch to the server's command line to have it download automatically:

-sdkfileid=226726898

1b) OR, download the mod with a client (using the launcher) and upload it to the server's UDKGame/CookedSDK/__CMWSDKFiles directory

2a) After logging in as an admin:

admin servertravel aocffa-arena3_p?modname=giantslayers
(note: Giant Slayers will now run as your default mode until you either servertravel to a different mod, or restart the server)

2b) OR, start the server with ?modname=giantslayers appended to the map name; an example of a full command line including the -sdkfileid:

chivalry_ded_server/Binaries/Win64/UDK.exe aocffa-arena3_p?dedicated=true?steamsockets?modname=giantslayers -seekfreeloadingserver -sdkfileid=226726898
