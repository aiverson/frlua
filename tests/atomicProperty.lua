--Copyright 2016 Alex Iverson

local fr = require "fr"
local test = require"tests.test"

test("atomic property updates", function(assertion)
  local bus = fr.Bus()

  local prop = bus:toProperty(0);
  prop.name = "busProp"

  local termAlpha = prop + fr.constant(3)
  termAlpha.name = "Alpha"
  local termBeta = prop + termAlpha
  termBeta.name = "Beta"
  local termGamma = prop + termBeta
  termGamma.name = "Gamma"
  termGamma:onValue(assertion:expectSequenceEqual{3, 18, 15, 21, 30, 24})

  bus:plug(fr.fromTable{5, 4, 6, 9, 7})
end):runLog()