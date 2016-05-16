--Copyright 2016 Alex Iverson
--credit to BaconJS for the algorithm

local property = require "fr.property"
local isObservable = require "fr.isObservable"

local function applyStreamValue(key, index)
  return function(stack, vals)
    stack[#stack][key] = vals[index]
  end
end
local function constantValue(key, value)
  return function(stack, vals)
    stack[#stack][key] = value
  end
end
local function pushContext(key, value)
  return function(stack, vals)
    local newContext = {}
    stack[#stack][key] = newContext
    stack[#stack+1] = newContext
  end
end
local function popContext(stack, vals)
  stack[#stack] = nil
end
local compileTemplate
local function compile(key, value, funcs, streams)
  if isObservable(value) then
    streams[#streams+1] = value
    funcs[#funcs+1] = applyStreamValue(key, #streams)
  elseif type(value) == "table" then
    funcs[#funcs+1] = pushContext(key, value)
    compileTemplate(value, funcs, streams)
    funcs[#funcs+1] = popContext
  else
    funcs[#funcs+1] = constantValue(key, value)
  end
end
function compileTemplate(template, funcs, streams)
  for k, v in pairs(template) do
    compile(k, v, funcs, streams)
  end
end

local function combineTemplate(template)
  local funcs = {}
  local streams = {}
  compileTemplate(template, funcs, streams)
  local prop = property.combineAsArray(streams):map(
    function(values)
      local stack = {{}}
      for i=1,#funcs do
        funcs[i](stack, values)
      end
      return stack[1]
    end
  )
  return prop
end

return combineTemplate