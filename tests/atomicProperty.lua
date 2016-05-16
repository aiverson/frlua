--Copyright 2016 Alex Iverson

local fr = require "fr"

local bus = fr.Bus()

fr.constant("test"):onValue(print)

local prop = bus:toProperty(0);
prop:onValue(print);
prop.name = "busProp"

local termAlpha = prop + fr.constant(3)
termAlpha.name = "Alpha"
local termBeta = prop + termAlpha
termBeta.name = "Beta"
local termGamma = prop + termBeta
termGamma.name = "Gamma"
termGamma:onValue(print)

bus:plug(fr.fromTable{5, 4, 6, 9, 7})
