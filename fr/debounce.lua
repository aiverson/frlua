local eventStream = require "fr.eventStream"
local property = require "fr.property"
local time = require "fr.time"

if not time.hasTimeout then
  function eventStream:debounce(delay)
    time.needTimeout()
  end
  function property:debounce(delay)
    time.needTimeout()
  end
  return time.needTimeout
end


function eventStream:debounce(delay)
  local latestEvent = 0
  local timerCancel
  local stream = eventStream.fromBinder(function(sink)
      local subscribeCancel = self:subscribe(function(event, value)
          if event == "Next" then
            if timerCancel then timerCancel() end
            latestEvent = latestEvent + 1
            local evtIdx = latestEvent
            timerCancel = time.setTimeout(delay, function()
                if latestEvent == evtIdx then
                  latestEvent = 0
                  sink(event, value)
                end
              end
            )
          elseif event == "Error" then
            sink(event, value)
          elseif  event == "End" then
            if timerCancel then timerCancel() end
            sink(event, value)
          end
        end
      )
    end
  )
  stream.tag = "eventStream.debounce"
  stream[1] = self
  stream[2] = delay
  return stream
end

function property:debounce(delay)
  local latestEvent = 0
  local timerCancel
  local prop = property.fromBinder(function(sink, preupdate, updateReady)
      local subscribeCancel = self:subscribe(function(event, value)
          if event == "Next" then
            if timerCancel then timerCancel() end
            latestEvent = latestEvent + 1
            local evtIdx = latestEvent
            timerCancel = time.setTimeout(delay, function()
                if latestEvent == evtIdx then
                  latestEvent = 0
                  preupdate()
                  updateReady()
                  sink(event, value)
                end
              end
            )
          elseif event == "Error" then
            preupdate()
            updateReady()
            sink(event, value)
          elseif  event == "End" then
            if timerCancel then timerCancel() end
            preupdate()
            updateReady()
            sink(event, value)
          end
        end,
        function() end
      )
    end
  )
  prop.tag = "property.debounce"
  prop[1] = self
  prop[2] = delay
  return prop
end

return function(obj, delay)
  return obj:debounce(delay)
end
