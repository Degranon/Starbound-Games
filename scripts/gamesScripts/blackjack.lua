require "/scripts/gamesUtil.lua"

-- Blackjack functions

blackjackTables = {}

function blackjackInit(t, id, playerList, config)
  math.randomseed(os.time())
  math.random(); math.random(); math.random() -- Setting the generator properly ;)
  
  -- Retrieveing commands
  blackjackCommands = config.commands
  
  -- Generating the deck
  cardDeck = generateDeck(_52_ranks)
  
  -- Giving 0 cards
  for i = 1, #playerList do
    playerList[i].cards = {}
  end
  
  -- Dealing the cards
  deck, playerList = dealCards(deck, playerList, 1, 2)
  
  -- Setting the current game
  table.insert(blackjackTables, t, {deck = deck, players = playerList})
  
  -- Tell the commands, show the cards
  for i, player in ipairs(playerList) do
    universe.adminWhisper(player.id, "Type /commands to see available commands")
    universe.adminWhisper(player.id, blackjack_cards(player.id, t, i, {}))
	universe.adminWhisper(player.id, "Current sum: " .. countSum(player.cards))
  end
end

function blackjack_commands(id, t, p, args)
	local message = ""
	for name, desc in pairs(blackjackCommands) do
		message = message .. name .. ": " .. desc .. "\n"
	end
	return message

end

function blackjack_hit(id, t, p, args)
	local game = blackjackTables[t]
	local player = game.players[p]
	
	local sum = countSum(player.cards)
	
	if sum == 21 then return "^cyan;You already won! Now you just wait..." end
	if sum > 21 then return "^red;You already have more than 21! Now you just wait..." end
	
	local card = table.remove(deck)
    table.insert(player.cards, card)
	
	sendToAll(game.players, player.nick .. " made a hit")
	return blackjack_cards(id, t, p, {}) .. "; sum = " .. countSum(player.cards)
end

function blackjack_stand(id, t, p, args)
	local game = blackjackTables[t]
	local player = game.players[p]
	
	if not player.standed then
		sendToAll(game.players, player.nick .. " has standed")
	end
	
	player.standed = true
	
	if isGameOver(game.players) then
		blackjackUninit(t, id, game.players)
		return ""
	else
		return "Standed. Current sum is " .. countSum(player.cards)
	end
end

function blackjack_cards(id, t, p, args)
  local message = "Your current cards:\n"
  for i, c in ipairs(blackjackTables[t].players[p].cards) do
    message = message .. "^gray;" .. i .. ": " .. cardToText(c) .. " "
  end
  return message
end

function countSum(cards)
	local sum = 0
	local aces = 1
	for i, card in ipairs(cards) do
		-- if a number card
		if tonumber(card.rank) then
			sum = sum + tonumber(card.rank)
		else -- if a picture card
			if card.rank ~= "A" then -- if not an ace, add 10
				sum = sum + 10
			else -- else leave it for now
				aces = aces + 1
			end
		end
	end
	
	-- aces are counted differently
	for i = 1, aces - 1 do
		if sum <= 20 then
			sum = sum + 11
		else
			sum = sum + 1
		end
	end
	return sum
end

function isGameOver(players)
	if checkAllStanded(players) then
		local winners = findWinner(players)
		
		-- show all sums:
		sendToAll(players, "Cards:")
		for _, player in ipairs(players) do
			sendToAll(players, player.nick .. ": " .. countSum(player.cards))
		end
		
		-- reveal winners of the game:
		sendToAll(players, "Winners:")
		for _, winner in ipairs(winners) do
			sendToAll(players, winner.nick .. " has won!")
		end
		return true
	end
	return false
end

function checkAllStanded(players)
	for i, player in ipairs(players) do
		if not player.standed then
			return false
		end
	end
	return true
end

function findWinner(players)
	local winners = {}
	-- first, we check if we have players with 21 points
	for _, p in ipairs(players) do
		if countSum(p.cards) == 21 then
			table.insert(winners, p)
		end
	end
	
	-- if there are, return them
	if #winners > 0 then return winners end
	
	-- else we look whether everyone was busted
	local alive = {} -- players with less than 21 points
	for _, p in ipairs(players) do
		if countSum(p.cards) < 21 then
			table.insert(alive, p)
		end
	end
	
	-- if there're players with less than 21 points, find the closest ones:
	
	local closest = 0
	if #alive > 0 then
		for _, p in ipairs(alive) do
			if math.abs(21 - countSum(p.cards)) < 21 - closest then closest = countSum(p.cards) end
		end
		
		for _, p in ipairs(alive) do
			if countSum(p.cards) == closest then table.insert(winners, p) end
		end
		
	else -- everyone is busted, find the closest one to 21:
		for _, p in ipairs(players) do
			if math.abs(21 - countSum(p.cards)) < closest then closest = countSum(p.cards) end
		end
		
		for _, p in ipairs(players) do
			if countSum(p.cards) == closest then table.insert(winners, p) end
		end
	end
	
	return winners
end


function blackjackUninit(t, id, players)
  table.remove(blackjackTables, t)
end