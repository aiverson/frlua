--Copyright 2016-2018 Alex Iverson


return function(FR)
--if time.hasGet then
  function FR.EventStream:debounceImmediate(delay)
    local lastTime = FR.time.now() - delay - 1
    local stream = FR.EventStream.fromBinder(function(sink)
        return self:subscribe(function(event, ...)
            if event == "Next" or event == "Initial" then
              local nowTime = FR.time.now()
              if nowTime - lastTime > delay then
                sink(event, ...)
                lastTime = nowTime
              end
            else
              sink(event, ...)
            end
          end
        )
      end
    )
    stream.tag = "eventStream.debounceImmediate"
    stream[1] = self
    stream[2] = delay
    return stream
  end
  function FR.Property:debounceImmediate(delay)
    local lastTime
    local ready = true
    local prop = FR.Property.fromBinder(function(sink, preupdate, updateReady)
        return self:subscribe(function(event, ...)
            if event == "Next" or event == "Initial" then
              local nowTime = FR.time.now()
              if ready then
                updateReady()
                sink(event, ...)
                lastTime = nowTime
                ready = false
              end
            else
              if not ready then
                preupdate()
              end
              updateReady()
              sink(event, ...)
            end
          end,
          function()
            local nowTime = FR.time.now()
            if nowTime - lastTime > delay then
              ready = true
              preupdate()
            end
          end
        )
      end
    )
    prop.tag = "property.debounceImmediate"
    prop[1] = self
    prop[2] = delay
    return prop
  end--[[
elseif time.hasTimeout then
  function eventStream:debounceImmediate(delay)
    local ready = true
    local stream = eventStream.fromBinder(function(sink)
        return self:subscribe(function(event, ...)
            if event == "Next" or event == "Initial" then
              print("debounceImmediate", ready, event, ...)
              if ready then
                sink(event, ...)
                print "debounce immediate setting timer"
                time.setTimeout(delay, function()
                    ready = true
                    print "debounceImmediate ready"
                  end)
                ready = false
              end
            else
              sink(event, ...)
            end
          end
        )
      end
    )
    stream.tag = "eventStream.debounceImmediate"
    stream[1] = self
    stream[2] = delay
    return stream
  end
  function property:debounceImmediate(delay)
    local ready = true
    local preupdated = false
    local prop = property.fromBinder(function(sink, preupdate, updateReady)
        return self:subscribe(function(event, ...)
            if event == "Next" or event == "Initial" then
              if ready then
                updateReady()
                sink(event, ...)
                time.setTimeout(delay, function() ready = true end)
                ready = false
                preupdated = false
              end
            else
              if not preupdated then
                preupdate()
              end
              updateReady()
              sink(event, ...)
              preupdated = false
            end
          end,
          function()
            if ready then
              preupdate()
              preupdated = true
            end
          end
        )
      end
    )
    prop.tag = "property.debounceImmediate"
    prop[1] = self
    prop[2] = delay
    return prop
  end
else
  function eventStream:debounceImmediate()
    time.needGetOrTimeout()
  end
  function property:debounceImmediate()
    time.needGetOrTimeout()
  end
end]]

  function FR.debounceImmediate(obj, delay)
    return obj:debounceImmediate(delay)
  end
end
