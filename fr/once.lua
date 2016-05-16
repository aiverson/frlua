--Copyright 2016 Alex Iverson

local eventStream = require"fr.eventStream"

local function once(value)
  local published = false
  return eventStream.create(function(self, other)
      if not published then
        published = true
        if not other("Next", value) then
          other("End")
        end
      else
        other("End")
      end
      return function() end
    end)
end

return once