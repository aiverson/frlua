--Copyright 2016 Alex Iverson

local eventStream = require"fr.eventStream"
local property = require"fr.property"

return function(obj)
  return eventStream.isEventStream(obj) or property.isProperty(obj)
end