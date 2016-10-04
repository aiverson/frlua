--Copyright 2016 Alex Iverson

local eventStream = require"fr.eventStream"

local function repeatStream(f)
  local iterations = 1
  return eventStream.fromBinder(function(sink)
      local flag = false
      local reply = false
      local function unsub() end
      local subscribeNext
      local function handle(event, ...)
        if event == "End" then
          if not flag then
            flag = true
          else
            subscribeNext()
          end
        else
          reply = sink(event, ...)
        end
      end
      function subscribeNext()
        flag = true
        while flag and not reply do
          local nextStream = f(iterations)
          iterations = iterations + 1
          flag = false
          if nextStream then
            unsub = nextStream:subscribe(handle)
          else
            sink("End")
          end
        end
        flag = true
      end
      subscribeNext()
      return function() unsub() end
    end)
end

return repeatStream