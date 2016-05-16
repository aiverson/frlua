--Copyright 2016 Alex Iverson

local eventStream = require"fr.eventStream"
local tremove = table.remove

local function Bus()
  local busEvent
  local subscriptions = {}
  local unsubStream
  local function noHandler() return true end
  local newBus = eventStream.fromBinder(function(sink)
      busEvent = function(...)
        if sink(...) then
          busEvent = noHandler
          return true
        end
        return false
      end
      for i=1, #subscriptions do
        subscriptions[i].unsub = subscriptions[i].input:subscribe(function(...) return busEvent(...) end)
      end
      return function()
        busEvent = noHandler
        for i=1, #subscriptions do
          if subscriptions[i].unsub then
            subscriptions[i].unsub()
          end
        end
      end
    end)
  function newBus:push(...)
    return busEvent("Next", ...)
  end
  function newBus:error(...)
    return busEvent("Error", ...)
  end
  function newBus:End(...)
    return busEvent("End", ...)
  end
  function newBus:event(...)
    return busEvent(...)
  end
  function unsubStream(stream)
    for i=1, #subscriptions do
      local subscription = subscriptions[i]
      if subscription.input == stream then
        if subscription.unsub then
          subscription.unsub()
        end
        tremove(subscriptions, i)
        return
      end
    end
  end
  function newBus:plug(stream)
    local newSub = {
      input = stream
    }
    if busEvent ~= noHandler then
      newSub.unsub = stream:subscribe(function(event, ...)
          if event == "End" then
            unsubStream(stream)
          else
            return busEvent(event, ...)
          end
        end)
    end
    return function() unsubStream(stream) end
  end
  newBus.tag = "bus"
  return newBus
end

return Bus