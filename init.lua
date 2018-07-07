-- Copyright 2016 Alex Iverson

local tunpack = table.unpack or unpack
local tremove = table.remove
local tinsert = table.insert

local function makeFR(settings)

  local FR = {}
  
  if settings.time then
    if settings.time == "real" then
      FR.time = require './realtime'
    else
      FR.time = settings.time
    end
  end
  

  require"./eventStream"(FR)
  require"./property"(FR)

  require"./debounce"(FR)
  require"./debounceImmediate"(FR)

  FR.fromBinder = FR.EventStream.fromBinder

  require"./once"(FR)
  require"./fromTable"(FR)
  require"./repeat"(FR)
  require"./never"(FR)
  require"./defer"(FR)

  require"./bus"(FR)


  FR.EventStream.toProperty = FR.Property.fromEventStream

  FR.fromCallback = FR.EventStream.fromCallback

  FR.constant = FR.Property.constant

  FR.propertyFromBinder = FR.Property.fromBinder

  FR.isEventStream = FR.EventStream.isEventStream
  FR.isProperty = FR.Property.isProperty

  require"./isObservable"(FR)

  FR.combineAsArray = FR.Property.combineAsArray

  require"./combineTemplate"(FR)
  
  function FR.withFakeTime(basetime)
    local fakeTime = require './faketime'
    local newSettings = {}
    for k, v in pairs(settings) do
      newSettings[k] = v
    end
    newSettings.time = fakeTime(FR.time, basetime or FR.time.now())
    return makeFR(settings)
  end
  
  return FR
end

return makeFR{time="real"}