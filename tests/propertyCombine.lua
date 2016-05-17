--Copyright 2016 Alex Iverson

local fr = require "fr"
local test = require "tests.test"
local xlua = require"xlua"

test("property combine", function(assertion)
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

  location:each(assertion:expectSequenceTableMatch{
      {x=1, y=1, val=1},
      {x=2, y=1, val=4},
      {x=2, y=3, val=6},
      {x=2, y=2, val=5}})

  rowBus:push(2)
  colBus:push(3)
  colBus:push(2)
  end):runLog()