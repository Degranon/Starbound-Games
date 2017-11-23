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