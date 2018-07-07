--Copyright 2016-2018 Alex Iverson

return function(FR)

  function FR.EventStream:debounce(delay)
    local latestEvent = 0
    local timerCancel
    local stream = FR.EventStream.fromBinder(function(sink)
        local subscribeCancel = self:subscribe(function(event, value)
            if event == "Next" then
              if timerCancel then timerCancel() end
              latestEvent = latestEvent + 1
              local evtIdx = latestEvent
              timerCancel = FR.time.setTimeout(delay, function()
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

  function FR.Property:debounce(delay)
    local latestEvent = 0
    local timerCancel
    local prop = FR.Property.fromBinder(function(sink, preupdate, updateReady)
        local subscribeCancel = self:subscribe(function(event, value)
            if event == "Next" then
              if timerCancel then timerCancel() end
              latestEvent = latestEvent + 1
              local evtIdx = latestEvent
              timerCancel = FR.time.setTimeout(delay, function()
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

  function FR.debounce(obj, delay)
    return obj:debounce(delay)
  end

end