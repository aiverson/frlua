--Copyright 2016 Alex Iverson

local fr = require "fr"
local xlua = require"xlua"

local array = fr.constant({
    {1, 2, 3},
    {4, 5, 6},
    {7, 8, 9}
  })

local rowBus = fr.bus()
local row = rowBus:toProperty(1)

local colBus = fr.bus()
local col = colBus:toProperty(1)

local arrayRow = array:combine(row, "[")
arrayRow.name = "arrayRow"
local value = arrayRow:combine(col, "[")
value.name = "value"

local location = fr.combineTemplate{x=row, y=col, val=value}
location.name = "location"

location:each(xprint)

rowBus:push(2)
colBus:push(3)
colBus:push(2)