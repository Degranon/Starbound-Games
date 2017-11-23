# Starbound-Games
TableTop game engine created especially for starbound

This is a core script for adding your own tabletop games into Starbound, based on the processor commands scripts. You can find an example game durak inside.

# Usage
To add your game to the script, you should add your game *name* to the `availableGames` array in the `serverGames.lua` (may be changed in the future); then in the **/gameScripts** folder put your *name*.lua and *name*.config files.

Every *name*.lua file must contain three functions: ``*name*Init`` and ``*name*Uninit`` functions for setting the single game with the current id and list of players.

In-game commands should be constructed in the following template:

```lua
game_name(id, table, position, args)
```

where:

* **game** - the name of the game,
* **name** - the name of the executed command, 
* **id** - connection id
* **table** - the table (player array) the player is currently in
* **position** - the position in the array
* **args** - command arguments
