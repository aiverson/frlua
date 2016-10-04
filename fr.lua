-- Copyright 2016 Alex Iverson

local tunpack = table.unpack or unpack
local tremove = table.remove
local tinsert = table.insert

local FR = {}

local EventStream = require"fr.eventStream"

require"fr.debounce"
require"fr.debounceImmediate"

FR.fromBinder = EventStream.fromBinder

FR.once = require"fr.once"
FR.Once = FR.once
FR.fromTable = require"fr.fromTable"
FR.FromTable = FR.fromTable
FR.Repeat = require"fr.repeat"
FR.never = require"fr.never"
FR.Never = FR.never
FR.defer = require"fr.defer"
FR.Defer = FR.defer

FR.bus = require"fr.bus"
FR.Bus = FR.bus

local Property = require"fr.property"

EventStream.toProperty = Property.fromEventStream

FR.fromCallback = EventStream.fromCallback

FR.constant = Property.constant

FR.propertyFromBinder = Property.fromBinder

FR.isEventStream = EventStream.isEventStream
FR.isProperty = Property.isProperty

FR.isObservable = require"fr.isObservable"

FR.combineAsArray = Property.combineAsArray

FR.combineTemplate = require"fr.combineTemplate"

return FR