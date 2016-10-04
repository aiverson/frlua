local eventStream = require"fr.eventStream"
local time = require"fr.time"

if not time.hasTimeout then
  return time.needTimeout
end

local function defer(delay, value)
  local done = false
  local stream = eventStream.fromBinder(function(sink)
      if not done then
        return time.setTimeout(delay, function()
            done = true
            sink("Next", value)
            sink("End")
          end
        )
      else
        return function() end
      end
    end
  )
  stream.tag = "fr.defer"
  stream[1] = delay
  stream[2] = value
  return stream
end

return defer