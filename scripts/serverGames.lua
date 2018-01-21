require "/scripts/util.lua"
require "/scripts/gamesUtil.lua"


local activeTables = {}
local availableGames = {"durak", "blackjack"}
local commands = {}

function init()
  math.randomseed(os.time())
    self.configs = {}
  -- require globally
  for _, name in ipairs(availableGames) do
    require ("/scripts/gamesScripts/" .. name .. ".lua")
    self.configs[name] = root.assetJson("/scripts/gamesScripts/"..name..".config")
  end
end

local oldCommand = command

function command(name, id, args)
  if type(commands[name]) == "function" and commands[name] then
    return commands[name](id, args)
  else
    local playerNick = universe.clientNick(id)
    local player = {id = id, nick = playerNick}
    local t, p = getPlayerTable(player, activeTables)
	
    if t ~= 0 then
	  local gameType = activeTables[t].game
	  local cfg = self.configs[gameType]
	  local cmd = gameType .. "_" .. name
	  sb.logInfo("%s", cfg)
	  if cfg.commands[name] and type(_ENV[cmd]) == "function" and _ENV[cmd] then
        return (_ENV[cmd])(id, t, p, args)
      else
	    return "^blue;Command not found"
	  end
	end
  end
  if oldCommand then return oldCommand(name, id, args) end
end

---------------------------------- GAMES ------------------------------------------

function greetUsers(playerTable, gameType)
  for k,v in pairs(playerTable) do
    message = "Welcome, " .. v.nick .. ", to the " .. gameType .. " game! You'll play against "

    for _, player in ipairs(playerTable) do
      if player.id ~= v.id then
        message = message .. player.nick .. ", "
      end
    end
    
    universe.adminWhisper(v.id, message .. ". Good luck!")
  end
end

function farewellUsers(playerTable, gameType)
  for k,v in pairs(playerTable) do
    universe.adminWhisper(v.id, "Your " .. gameType .. " game was finished!")
  end
end

  
function commands.join(id, args)
  if #args == 0 then return commands.games(id, nil) end
  
  local playerNick = universe.clientNick(id)
  local player = {id = id, nick = playerNick}
  local cmd = args[1]
  local t, _ = getPlayerTable(player, activeTables)
  
  if tonumber(cmd) == nil or not isInt(tonumber(cmd)) then
	if not valueExists(availableGames, cmd) then 
		return "The " .. cmd .. " game does not exist!"
	else
		if t == 0 then
		  table.insert(activeTables, {game = cmd, admin = player, players = {player}, started = false})
		  gameId = #activeTables
		  return "You have initiated the " .. cmd .. " game! Your table id is: " .. gameId
		else
		  return "You are already sitting at the " .. t .. " table! Type /leave to leave the current table"
		end
	end
  else
	gameId = tonumber(cmd)
	if activeTables[gameId] ~= nil and activeTables[gameId].started then 
		return "The " .. gameId .. " table has already started!"
	elseif activeTables[gameId] == nil then
		return "Table " .. gameId .. " is empty!"
    elseif idExists(activeTables[gameId].players, id) then
		return "You are already at the " .. gameId .. " table!"
    else
      for _, v in pairs(activeTables[gameId].players) do
		universe.adminWhisper(v.id, playerNick .. " has joined the table!")
      end
      table.insert(activeTables[gameId].players, player)
      return "You have joined the " .. gameId .. " table (" .. activeTables[gameId].game .. "). Waiting for other players..."
    end
  end
end


function commands.leave(id, args)
  local playerNick = universe.clientNick(id)
  local player = {id = id, nick = playerNick}
  
  local t, p = getPlayerTable(player, activeTables)
  
  if t ~= 0 then
    table.remove(activeTables[t].players, p)
  if #activeTables[t].players == 0 then
    table.remove(activeTables, t)
  else
    for _, v in pairs(activeTables[t].players) do
    universe.adminWhisper(v.id, playerNick .. " has left the game!")
    end
    --TODO: _ENV[gameType.."Update"](t, id, activeTables[t].players)
  end
  return "You have left the " .. t .. " table!"
  else
    return "You are not at any table!"
  end
end

function commands.availablegames(id, args)

  if #availableGames == 0 then return "No games are yet available!" end
  
  message = "Available games are: "
  
  for i = 1, #availableGames do
    message = message .. availableGames[i] .. " "
  end
  return message
end


function commands.games(id, args)

  if #activeTables == 0 then return "No games are going!" end
  
  gameType = (args ~= nil) and args[1] or nil
  s = (gameType == nil) and "" or gameType
  message = "Current " .. s .. " games:"
  for t, gameTable in pairs(activeTables) do
    if not gameType or gameTable.game == gameType then
      g = (s == "") and "(" .. gameTable.game .. ") " or ""
      ps = " "
      
      for _, i in ipairs(gameTable.players) do
        ps = ps .. i.nick .. " "
      end
      
      message = message .. "\n" .. g .. t .. ": " .. ps
    end
  end
  return message
end

function commands.finishgame(id, args)
  local playerNick = universe.clientNick(id)
  local player = {id = id, nick = playerNick}
  
  local t, p = getPlayerTable(player, activeTables)
  
  if t == 0 then 
    return "You are not playing at any table! Type /game to see the current games or type /availablegames to start a new one!"
  elseif not activeTables[t].started then
    return "Your game was not started!"
  elseif activeTables[t].admin.id ~= id then
    return "Only hosts of the tables can finish the game!\n" .. activeTables[t].admin.nick .. " is the host of your table!"
  else
    local gameType = activeTables[t].game
      
    farewellUsers(activeTables[t].players, gameType)
    _ENV[gameType.."Uninit"](t, id, activeTables[t].players)
  table.remove(activeTables, t)
  end
  
  return ""
end

function commands.startgame(id, args)
  
  local playerNick = universe.clientNick(id)
  local player = {id = id, nick = playerNick}
  
  local t, p = getPlayerTable(player, activeTables)
  
  if t == 0 then 
    return "You are not playing at any table! Type /game to see the current games or type /availablegames to start a new one!"
  elseif activeTables[t].started then
    return "Your game was already started!"
  elseif activeTables[t].admin.id ~= id then
    return "Only hosts of the tables can start the game!\n" .. activeTables[t].admin.nick .. " is the host of your table!"
  else
    local gameType = activeTables[t].game
  
    local config = self.configs[gameType]
    local nOfPlayers = #(activeTables[t].players)
    
    if nOfPlayers > config.maxPlayers then
      return "Too many players to start, " .. config.maxPlayers .. " maximum."
    elseif nOfPlayers < config.minPlayers then
      return "Not enought players to start, " .. config.minPlayers .. " minimum"
    else
      activeTables[t].started = true
      
      greetUsers(activeTables[t].players, gameType)
      _ENV[gameType.."Init"](t, id, activeTables[t].players, config)
    end
  end
  
  return ""
end