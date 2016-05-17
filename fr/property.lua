--Copyright 2016 Alex Iverson

local funcTools = require"fr.functionTools"
local createFunction = funcTools.createFunction

local tinsert = table.insert
local tremove = table.remove

local PropertyMetatable
local Property

local function fromEventStream(stream, initial)
  local subscribers = {}
  local preupdates = {}
  local nSubscribers = 0
  local unsub
  local function sink(event, val)
    if event == "Initial" or event == "Next" then
      initial = val
    end
    for i=1, nSubscribers do
      preupdates[i]()
    end
    local i = 1
    while i <= nSubscribers do
      local finished = subscribers[i](event, val)
      if finished then
        tremove(subscribers, i)
        nSubscribers = nSubscribers - 1
      else
        i = i + 1
      end
    end
    if nSubscribers == 0 then
      unsub = nil
      return true
    else
      return false
    end
  end
  local prop = Property.create(function(self, other, preupdate)
      preupdate()
      if not other("Initial", initial) then
        tinsert(subscribers, other)
        tinsert(preupdates, preupdate)
        nSubscribers = nSubscribers + 1
        if not unsub then
          unsub = stream:subscribe(sink)
        end
      end
      return function()
        for i=1, #subscribers do
          if subscribers[i] == other then
            tremove(subscribers, i)
            tremove(preupdates, i)
            nSubscribers = nSubscribers - 1
            if nSubscribers == 0 then
              unsub()
              unsub = nil
            end
            return
          end
        end
      end
    end)
  prop.tag = "Property.FromEventStream"
  prop[1] = stream
  return prop
end

local function propertyFromBinder(binder)
  local subscribers = {}
  local preupdates = {}
  local nSubscribers = 0
  local pending = 0
  local currentValue
  local hasCurrent
  local unsub
  local prop
  local function sink(event, ...)
    if pending ~= 0 then
      return
    end
    if event == "Next" or event == "Initial" then
      hasCurrent = true
      currentValue = ...
    end
    local i = 1
    while i <= nSubscribers do
      local finished = subscribers[i](event, ...)
      if finished then
        tremove(subscribers, i)
        tremove(preupdates, i)
        nSubscribers = nSubscribers - 1
      else
        i = i + 1
      end
    end
    if nSubscribers == 0 then
      return true
    else
      return false
    end
  end
  local function preupdate()
    --print(("preupdating %s, %d updates pending"):format(prop.name or "anonymous " .. prop.tag .. tostring(prop):sub(7), pending))
    if pending == 0 then
      --print(("%s triggering subscriber preupdates"):format(prop.name or "anonymous ".. prop.tag .. tostring(prop):sub(7)))
      for i=1, nSubscribers do
        preupdates[i]()
      end
    end
    pending = pending + 1
  end
  local function updateReady()
    --print(("readying %s, %d updates pending"):format(prop.name or "anonymous ".. prop.tag .. tostring(prop):sub(7), pending))
    pending = pending - 1
    return pending == 0
  end
  prop = Property.create(function(self, other, otherPreupdate)
      if hasCurrent then otherPreupdate() end
      if not hasCurrent or not other("Initial", currentValue) then
        tinsert(subscribers, other)
        tinsert(preupdates, otherPreupdate)
        nSubscribers = nSubscribers + 1
        if not unsub then
          unsub = binder(sink, preupdate, updateReady)
        end
      end
      return function()
        for i=1, #subscribers do
          if subscribers[i] == other then
            tremove(subscribers, i)
            tremove(preupdates, i)
            nSubscribers = nSubscribers - 1
            return
          end
        end
      end
    end)
  prop.tag = "property.fromBinder"
  return prop
end


Property = {
  combine = function(self, other, f, ...)
    local combineFunc = createFunction(f, ...)
    local valA, valB
    local haveA, haveB
    local unsubA, unsubB
    local prop = propertyFromBinder(function(sink, preupdate, updateReady)
        unsubA = self:subscribe(function(event, value)
            --print(("%s recieved %s %s from %s"):format(prop.name, event, value, self.name))
            if event == "Next" or event == "Initial" then
              valA = value
              haveA = true
              if haveB and updateReady() then
                return sink(event, combineFunc(valA, valB))
              end
            else
              if updateReady() then 
                return sink(event, value)
              end
            end
          end, function()
            --print(("preupdate propagating from %s to %s"):format(self.name, prop.name))
            if haveB then preupdate() end
          end)
        unsubB = other:subscribe(function(event, value)
            --print(("%s recieved %s %s from %s"):format(prop.name, event, value, other.name))
            if event == "Next" or event == "Initial" then
              valB = value
              haveB = true
              if haveA and updateReady() then
                return sink(event, combineFunc(valA, valB))
              end
            else
              if updateReady() then 
                return sink(event, value)
              end
            end
          end, function()
            --print(("preupdate propagating from %s to %s"):format(other.name, prop.name))
            if haveA then preupdate() end
          end)
        return function() unsubA(); unsubB() end
      end)
    prop.tag = "Property.Combine"
    prop[1] = self
    prop[2] = other
    prop[3] = f
    return prop
  end,
  combineAsArray = function(props)
    local latestValues = {}
    local unsubs = {}
    local initialized = {}
    local allInitialized = false
    local prop = propertyFromBinder(
      function(sink, preupdate, updateReady)
        for i = 1, #props do
          unsubs[i] = props[i]:subscribe(
            function(event, value)
              if event == "Initial" then
                initialized[i] = true
                latestValues[i] = value
                if not allInitialized then
                  for j = 1, #props do
                    if not initialized[j] then
                      return
                    end
                  end
                  allInitialized = true
                end
                local ready = updateReady()
                if ready then
                  local vals = {}
                  for j=1,#props do
                    vals[j] = latestValues[j]
                  end
                  sink(event, vals)
                end
              elseif event == "Next" then
                latestValues[i] = value
                if updateReady() then
                  local vals = {}
                  for j=1,#props do
                    vals[j] = latestValues[j]
                  end
                  sink(event, vals)
                end
              else
                sink(event, value)
              end
            end,
            function()
              if not allInitialized then
                for j = 1, #props do
                  if not initialized[j] and i ~= j then
                    return
                  end
                end
              end
              preupdate()
            end
          )
        end
        return function()
          for i = 1, #props do
            unsubs[i]()
          end
        end
      end
    )
    prop.tag = "property.combineAsArray"
    return prop
  end,
  onValue = function(self, f, ...)
    local eachFunc = createFunction(f, ...)
    return self:subscribe(function(event, ...)
        if event == "Next" or event == "Initial" then
          eachFunc(...)
        end
        return false
      end,
      function() --[[print("onValue recieved preupdate")]] end)
  end,
  onError = function(self, f, ...)
    local errFunc = createFunction(f, ...)
    return self:subscribe(function(event, ...)
        if event == "Error" then
          return errFunc(...)
        else
          return false
        end
      end,
      function() end)
  end,
  onEnd = function(self, f, ...)
    local endFunc = createFunction(f, ...)
    return self:subscribe(function(event, ...)
        if event == "End" then
          endFunc(...)
          return true
        else
          return false
        end
      end,
      function() end)
  end,
  map = function(self, f, ...)
    local mapFunc = createFunction(f, ...)
    local prop = propertyFromBinder(function(sink, preupdate, updateReady)
        return self:subscribe(function(event, ...)
            if event == "Next" or event == "Initial" then
              if updateReady() then
                return sink(event, mapFunc(...))
              end
            else
              if updateReady() then
                return sink(event, ...)
              end
            end
          end, preupdate)
      end)
    prop.tag = "property.map"
    return prop
  end,
  mapError = function(self, f, ...)
    local mapFunc = createFunction(f, ...)
    local prop = propertyFromBinder(function(sink, preupdate, updateReady)
        return self:subscribe(function(event, ...)
            if event == "Error" then
              if updateReady() then
                return sink("Next", mapFunc(...))
              end
            else
              if updateReady() then
                return sink(event, ...)
              end
            end
          end, preupdate)
      end)
    prop.tag = "property.map"
    return prop
  end,
  Not = function(self)
    return self:map(function(val) return not val end)
  end,
  And = function(self, other)
    local prop = self:combine(other, function(a, b) return a and b end)
    prop.tag = "property.And"
    return prop
  end,
  Or = function(self, other)
    local prop = self:combine(other, function(a, b) return a or b end)
    prop.tag = "property.Or"
    return prop
  end,
  Xor = function(self, other)
    local prop = self:combine(other, function(a, b) return not a and b or not b and a end)
    prop.tag = "property.Xor"
    return prop
  end,
  eq = function(self, other)
    local prop = self:combine(other, function(a, b) return a == b end)
    prop.tag = "property.Eq"
    return prop
  end,
  ne = function(self, other)
    local prop = self:combine(other, function(a, b) return a ~= b end)
    prop.tag = "property.Ne"
    return prop
  end,
  gt = function(self, other)
    local prop = self:combine(other, function(a, b) return a > b end)
    prop.tag = "property.gt"
    return prop
  end,
  lt = function(self, other)
    local prop = self:combine(other, function(a, b) return a < b end)
    prop.tag = "property.lt"
    return prop
  end,
  ge = function(self, other)
    local prop = self:combine(other, function(a, b) return a >= b end)
    prop.tag = "property.ge"
    return prop
  end,
  le = function(self, other)
    local prop = self:combine(other, function(a, b) return a <= b end)
    prop.tag = "property.le"
    return prop
  end,
}

Property.each = Property.onValue

local function add(a, b) return a + b end
local function mul(a, b) return a * b end
local function sub(a, b) return a - b end
local function div(a, b) return a / b end
--TODO: Finish combination metamethods
PropertyMetatable = {
  __index = Property,
  __add = function(self, other)
    local prop = self:combine(other, add)
    prop.tag = "property.add"
    return prop
  end,
  __mul = function(self, other)
    local prop = self:combine(other, mul)
    prop.tag = "property.mul"
    return prop
  end,
  __sub = function(self, other)
    local prop = self:combine(other, sub)
    prop.tag = "property.sub"
    return prop
  end,
  __div = function(self, other)
    local prop = self:combine(other, div)
    prop.tag = "property.div"
    return prop
  end,
  __type = "fr.property"
}

function Property.create(subscribe)
  return setmetatable({subscribe = subscribe}, PropertyMetatable)
end

function Property.isProperty(obj)
  return getmetatable(obj) == PropertyMetatable
end

function Property.constant(value)
  local prop = Property.create(function(self, sink, preupdate)
      preupdate()
      sink("Initial", value)
    end)
  prop.tag = "Property.Constant"
  prop[1] = value
  return prop
end

Property.fromBinder = propertyFromBinder

Property.fromEventStream = fromEventStream

return Property
