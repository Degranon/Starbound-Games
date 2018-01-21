function init()
  self.chatOptions = config.getParameter("chatOptions", {})
  self.chatTimer = 0
  self.chatIndex = 0
end

function update(dt)
  self.chatTimer = math.max(0, self.chatTimer - dt)
  if self.chatTimer == 0 then
    local players = world.entityQuery(object.position(), config.getParameter("chatRadius", 0), {
      includedTypes = {"player"},
      boundMode = "CollisionArea"
    })

    if #players > 0 and #self.chatOptions > 0 then
      object.say(self.chatOptions[(self.chatIndex % #self.chatOptions) + 1])
	  self.chatIndex = self.chatIndex + 1
      self.chatTimer = config.getParameter("chatCooldown")
    end
  end
end