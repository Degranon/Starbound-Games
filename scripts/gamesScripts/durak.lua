require "/scripts/gamesUtil.lua"

-- Durak functions

durakTables = {}
local durak = {}
local ranks = {"6", "7", "8", "9", "10", "J", "Q", "K", "A"}
local inverted_ranks = {["6"] = 1, ["7"] = 2, ["8"] = 3, ["9"] = 4, ["10"] = 5, ["J"] = 6, ["Q"] = 7, ["K"] = 8, ["A"] = 9}
local suits = {"^orange;ª", "^red;«", "^cyan;§", "^darkgreen;°"}

function durakInit(t, id, playerList, config)
  math.randomseed(os.time())
  math.random(); math.random(); math.random() -- Setting the generator properly ;)
  
  -- Retrieveing commands
  durakCommands = config.commands
  
  -- Generating the deck
  cardDeck = generateDeck()
  
  -- Shuffling the order
  playerList = shuffle(playerList)
  
  -- Giving 0 cards
  for i = 1, #playerList do
    playerList[i].cards = {}
  end
  
  -- Dealing the cards
  deck, playerList = dealCards(deck, playerList, 1)
  
  -- Retrieving the trump suit
  trump = deck[1]
  
  -- Setting the current game
  table.insert(durakTables, t, {deck = deck, players = playerList, trump = trump, tableCards = {}, playerTurn = 1, fCard = nil})
  
  -- Tell the commands, show the cards
  for i, player in ipairs(playerList) do
    universe.adminWhisper(player.id, "Type /commands to see available commands")
    universe.adminWhisper(player.id, "Trump now is " .. cardToText(trump))
    universe.adminWhisper(player.id, durak_cards(player.id, t, i, {}))
  end
  
  -- Notify players about the order
  notifyTurns(durakTables[t].players, durakTables[t].playerTurn)
end

function notifyTurns(players, playerIndex)
  universe.adminWhisper(players[playerIndex].id, "It's your turn!")
  universe.adminWhisper(players[playerIndex % #players + 1].id, "Prepare for defending yourself!")
end

function shuffle(tbl)
  size = #tbl
  for i = size, 1, -1 do
    local rand = math.random(size)
    tbl[i], tbl[rand] = tbl[rand], tbl[i]
  end
  return tbl
end

function generateDeck()
  deck = {}
  for _, r in ipairs(ranks) do
    for _, s in ipairs(suits) do
      table.insert(deck, {suit = s, rank = r})
    end
  end
  return shuffle(deck)
end

function dealCards(deck, players, pIndex)
  for i = pIndex, 1, -1 do
    while #(players[i].cards) < 6 and #deck > 0 do
      local card = table.remove(deck)
      table.insert(players[i].cards, card)
    end
  end
  
  for i = #players, pIndex + 1, -1 do
    while #(players[i].cards) < 6 and #deck > 0 do
      local card = table.remove(deck)
      table.insert(players[i].cards, card)
    end
  end
  
  return deck, players
end


function durak_cards(id, t, p, args)
  local message = "Your current cards:\n"
  for i, c in ipairs(durakTables[t].players[p].cards) do
    message = message .. "^gray;" .. i .. ": " .. cardToText(c) .. " "
  end
  return message
end

function durak_done(id, t, p, args)
	local game = durakTables[t]
	if p ~= game.playerTurn then
		return "Only " .. game.players[game.playerTurn].nick .. " can finish the round"
	elseif game.fCard == nil then
		return "You have to throw at least one card!"
	else
		for k,v in ipairs(game.tableCards) do
			if v.attackCard ~= nil and v.defendCard == nil then
				return "Not every card on the table is beaten!"
			end
		end
		nextRound(t, p, false)
	end
	return ""
end

function nextRound(t, p, skip)
  local game = durakTables[t]
  local nextPlayer = game.playerTurn % #(game.players) + 1
  
  game.deck, game.players = dealCards(game.deck, game.players, p)
  
  if skip then nextPlayer = nextPlayer % #(game.players) + 1 end	
  game.playerTurn = nextPlayer
  
  game.tableCards = {}
  game.fCard = nil
  if #(game.players[p].cards) == 0 then
	  for _, v in ipairs(game.players) do
        universe.adminWhisper(v.id, game.players[p].nick .. " has won!")
      end   
  elseif #(game.players[nextPlayer].cards) == 0 then
	  for _, v in ipairs(game.players) do
        universe.adminWhisper(v.id, game.players[nextPlayer].nick .. " has won!")
      end   
  else
	notifyTurns(game.players, game.playerTurn)
    for i, v in ipairs(game.players) do
	  universe.adminWhisper(v.id, durak_cards(id, t, i, args))
    end 
  end
end

function durak_trump(id, t, p, args)
	return "Current trump is " .. cardToText(durakTables[t].trump)
end

function durak_take(id, t, p, args)
  local game = durakTables[t]
  local defender = game.playerTurn % #(game.players) + 1
  
  if p ~= defender then
	return "Only defender can take all the cards"
  else
	if #(game.tableCards) == 0 then
	  return "There's nothing to take"
	else
	  for k,v in ipairs(game.tableCards) do
	    table.insert(game.players[p].cards, v.attackCard)
		if (v.defendCard ~= nil) then
		  table.insert(game.players[p].cards, v.defendCard)
		end
	  end
	  
	  for _, v in ipairs(game.players) do
        universe.adminWhisper(v.id, game.players[p].nick .. " has taken all the cards from the table!")
      end
	  
	  nextRound(t, p, true)
	end
  end
  return ""
end

function durak_commands(id, t, p, args)
	local message = ""
	for name, desc in pairs(durakCommands) do
		message = message .. name .. ": " .. desc .. "\n"
	end
	return message

end

function durak_beat(id, t, p, args)
  if #args < 2 then return "Usage: /durak beat tableCardIndex yourCardIndex" end
  
  local game = durakTables[t]
  local defender = game.playerTurn % #(game.players) + 1
  
  if p ~= defender then
    return "You are not defending right now"
  else
    local tableCardIndex = tonumber(args[1])
    local invCardIndex = tonumber(args[2])
    
    if tableCardIndex == nil or tableCardIndex <= 0 or invCardIndex == nil or invCardIndex <= 0 then
      return "Indices must be positive integers"
    elseif tableCardIndex > 6 then
      return "There can't be more than 6 cards on the table"
    elseif invCardIndex > #(game.players[p].cards) then
      return "You don't have " .. invCardIndex .. " cards"
    elseif game.tableCards == nil or #(game.tableCards) == 0 then
      return "There's nothing to beat yet"
    elseif tableCardIndex > (#game.tableCards) then
      return "There's no card at this place"
	elseif game.tableCards[tableCardIndex].defendCard ~= nill then
	  return "You've already beaten that card"
    elseif not isBeatable(game.tableCards[tableCardIndex].attackCard, game.players[p].cards[invCardIndex], game.trump) then
      return "You can't beat " .. cardToText(game.tableCards[tableCardIndex].attackCard) .. " with " .. cardToText(game.players[p].cards[invCardIndex])
    else
      local card = table.remove(game.players[p].cards, invCardIndex)
      game.tableCards[tableCardIndex].defendCard = card
      
      for _, v in ipairs(game.players) do
        universe.adminWhisper(v.id, game.players[p].nick .. " has beaten " .. cardToText(game.tableCards[tableCardIndex].attackCard) .. " with " .. cardToText(card))
      end
    end
  end
  return ""
end

function durak_table(id, t, p, args)
  local message = "Current table: "
  
  for k,v in ipairs(durakTables[t].tableCards) do
    local aCard = v.attackCard
    local dCard = v.defendCard
    
    if aCard ~= nil then
      message = message .. "\n^gray;" .. k .. ": " .. cardToText(aCard)
    end
    
    if dCard ~= nil then
      message = message .. "[" .. cardToText(dCard) .. "]"
    end
  end
  return message
end

function durak_throw(id, t, p, args)
  if #args ~= 1 then return "Usage: /durak throw cardIndex" end
  
  local game = durakTables[t]
  local defender = game.playerTurn % #(game.players) + 1
  
  if p == defender then
    return "You can't attack yourself!"
  elseif #(game.tableCards) == 6 then
    return "You can't add more than 6 cards on the table"
  elseif game.fCard == nil and p ~= game.playerTurn then
    return "The attacker has not made his move yet"
  else
    cardIndex = tonumber(args[1])
    if cardIndex == nil or cardIndex <= 0 or not isInt(cardIndex) then 
      return "cardIndex must be a positive integer" 
    else
      if cardIndex > #(game.players[p].cards) then
        return "You don't have " .. cardIndex .. " cards"
      elseif not checkTable(game.players[p].cards[cardIndex], game.tableCards) and game.fCard ~= nil then
        return "You can't put that card on the table!"
      else
        local card = table.remove(game.players[p].cards, cardIndex)
        table.insert(game.tableCards, {attackCard = card, belongsTo = p})
        if game.fCard == nil then game.fCard = card end
		
		for _, v in ipairs(game.players) do
          universe.adminWhisper(v.id, game.players[p].nick .. " has added " .. cardToText(card) .. " to the table!")
        end
        return ""
      end
    end
  end

  return "End"
end

function checkTable(card, tableCards)
  if tableCards == nil or #tableCards == 0 then return false end
  for _,v in ipairs(tableCards) do
    if (v.attackCard and v.attackCard.rank == card.rank) or (v.defendCard and v.defendCard.rank == card.rank) then
      return true
    end
  end
  return false
end

function isBeatable(attackCard, defendCard, trump)
  if attackCard.suit == trump.suit then
    return defendCard.suit == trump.suit and inverted_ranks[defendCard.rank] > inverted_ranks[attackCard.rank]
  else
    return defendCard.suit == trump.suit or inverted_ranks[defendCard.rank] > inverted_ranks[attackCard.rank]
  end
end

function cardToText(card)
  return card.suit .. card.rank .. "^reset;"
end

function durakUninit(t, id, players)
  table.remove(durakTables, t)
end
