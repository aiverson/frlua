local tunpack = table.unpack or unpack
local tremove = table.remove
local tinsert = table.insert

local FR = {}

local EventStream = require"fr.eventStream"

FR.fromBinder = EventStream.fromBinder

FR.once = require"fr.once"
FR.Once = FR.once
FR.fromTable = require"fr.fromTable"
FR.FromTable = FR.fromTable
FR.Repeat = require"fr.repeat"
FR.never = require"fr.never"
FR.Never = FR.never

FR.bus = require"fr.bus"
FR.Bus = FR.bus

local Property = require"fr.property"

EventStream.toProperty = Property.fromEventStream

FR.fromCallback = EventStream.fromCallback

FR.constant = Property.constant

FR.isEventStream = EventStream.isEventStream
FR.isProperty = Property.isProperty

function FR.isObservable(obj)
   return FR.isEventStream(obj) or FR.isProperty(obj)
end

FR.combineAsArray = Property.combineAsArray

require"fr.combineTemplate"(FR)

return FR