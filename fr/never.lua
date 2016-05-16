--Copyright 2016 Alex Iverson

local eventStream = require"fr.eventStream"

local function never()
  return eventStream.create(function(self, other)
      other("End")
      return function() end
    end)
end

return never