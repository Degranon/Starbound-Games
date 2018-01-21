-- CARD GAMES --

_36_ranks = {"6", "7", "8", "9", "10", "J", "Q", "K", "A"}
_52_ranks = {"1", "2", "3", "4", "5", "6", "7", "8", "9", "10", "J", "Q", "K", "A"}
inverted_ranks = {["6"] = 1, ["7"] = 2, ["8"] = 3, ["9"] = 4, ["10"] = 5, ["J"] = 6, ["Q"] = 7, ["K"] = 8, ["A"] = 9}
suits = {"^orange;ª", "^red;«", "^cyan;§", "^darkgreen;°"}


function cardToText(card)
  return card.suit .. card.rank .. "^reset;"
end

function shuffle(tbl)
  size = #tbl
  for i = size, 1, -1 do
    local rand = math.random(size)
    tbl[i], tbl[rand] = tbl[rand], tbl[i]
  end
  return tbl
end

function generateDeck(deck_type)
  deck = {}
  for _, r in ipairs(deck_type) do
    for _, s in ipairs(suits) do
      table.insert(deck, {suit = s, rank = r})
    end
  end
  return shuffle(deck)
end

function dealCards(deck, players, pIndex, max_amount)
  for i = pIndex, 1, -1 do
    while #(players[i].cards) < max_amount and #deck > 0 do
      local card = table.remove(deck)
      table.insert(players[i].cards, card)
    end
  end
  
  for i = #players, pIndex + 1, -1 do
    while #(players[i].cards) < max_amount and #deck > 0 do
      local card = table.remove(deck)
      table.insert(players[i].cards, card)
    end
  end
  
  return deck, players
end

-- UTIL --

function sendToAll(players, message)
	for _, v in ipairs(players) do
        universe.adminWhisper(v.id, message)
	end
end
function valueExists(tbl, value)
  for k,v in pairs(tbl) do
    if value == v then
      return true
    end
  end

  return false
end

function idExists(tbl, value)
  for k,v in pairs(tbl) do
    if value == v.id then
      return true
    end
  end

  return false
end

function palyersCheck(playerTable)
	for k,v in pairs(playerTable) do
		if not universe.isConnectedClient(v.id) or universe.clientNick(v.id) ~= v.nick then
			return false
		end
	end
	return true
end

function getPlayerTable(player, tables)
	if tables == nil then return 0 end
	for k,v in ipairs(tables) do
		for s,t in ipairs(v.players) do
			if t.id == player.id and t.nick == player.nick then
				return k, s
			end
		end
	end
	return 0
end

function isInt(n)
  return n==math.floor(n)
end