local commandFuncs = {}


function init()
  math.randomseed(os.time())
end

function command(name, id, args)
  if type(commandFuncs[name]) == "function" and commandFuncs[name] then
    return commandFuncs[name](id, args)
  else
    return "Command not found!"
  end
end

