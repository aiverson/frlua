
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
  local unsub
  local prop
  local function sink(...)
    if pending ~= 0 then return end
    --[[for i=1, nSubscribers do
      preupdates[i]()
    end]]
  local i = 1
  while i <= nSubscribers do
    local finished = subscribers[i](...)
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
  --print(("preupdating %s, %d updates pending"):format(prop.name, pending))
  if pending == 0 then
    --print(("%s triggering subscriber preupdates"):format(prop.name))
    for i=1, nSubscribers do
      preupdates[i]()
    end
  end
  pending = pending + 1
end
local function updateReady()
  --print(("readying %s, %d updates pending"):format(prop.name, pending))
  pending = pending - 1
  return pending == 0
end
prop = Property.create(function(self, other, otherPreupdate)
    otherPreupdate()
    if not other("Initial", currentValue) then
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
return prop
end


Property = {
  combine = function(self, other, f, ...)
    local combineFunc = createFunction(f, ...)
    local valA, valB
    local unsubA, unsubB
    local prop = propertyFromBinder(function(sink, preupdate, updateReady)
        unsubA = self:subscribe(function(event, value)
            --print(("%s recieved %s %s from %s"):format(prop.name, event, value, self.name))
            if event == "Next" or event == "Initial" then
              valA = value
              if updateReady() then
                return sink(event, combineFunc(valA, valB))
              end
            else
              if updateReady() then 
                return sink(event, value)
              end
            end
          end, function()
            --print(("preupdate propagating from %s to %s"):format(self.name, prop.name))
            preupdate()
          end)
        unsubB = other:subscribe(function(event, value)
            --print(("%s recieved %s %s from %s"):format(prop.name, event, value, other.name))
            if event == "Next" or event == "Initial" then
              valB = value
              if updateReady() then
                return sink(event, combineFunc(valA, valB))
              end
            else
              if updateReady() then 
                return sink(event, value)
              end
            end
          end, function()
            --print(("preupdate propagating from %s to %s"):format(other.name, prop.name))
            preupdate()
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
    local prop = propertyFromBinder(
      function(sink, preupdate, updateReady)
        for i = 1, #props do
          local idx = i
          unsubs[i] = props[i]:subscribe(
            function(event, value)
              if event == "Initial" then
                initialized[idx] = true
                latestValues[idx] = value
                local ready = updateReady()
                for j = 1, #props do
                  if not initialized[j] then
                    return
                  end
                end
                if ready then
                  local vals = {}
                  for j=1,#props do
                    vals[j] = latestValues[j]
                  end
                  sink(event, vals)
                end
              elseif event == "Next" then
                latestValues[idx] = value
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
    return prop
  end,
  Not = function(self)
    return self:map(function(val) return not val end)
  end
}

Property.each = Property.onValue

local function mul(a, b) return a * b end
local function sub(a, b) return a - b end
local function div(a, b) return a / b end
--TODO: Finish combination metamethods
PropertyMetatable = {
  __index = Property,
  __add = function(self, other)
    local valA, valB
    local unsubA, unsubB
    local prop = propertyFromBinder(function(sink, preupdate, updateReady)
        unsubA = self:subscribe(function(event, value)
            --print(("%s recieved %s %s from %s"):format(prop.name, event, value, self.name))
            if event == "Next" or event == "Initial" then
              valA = value
              if updateReady() then
                return sink(event, valA and valB and valA + valB)
              end
            else
              if updateReady() then 
                return sink(event, value)
              end
            end
          end, function()
            --print(("preupdate propagating from %s to %s"):format(self.name, prop.name))
            preupdate()
          end)
        unsubB = other:subscribe(function(event, value)
            --print(("%s recieved %s %s from %s"):format(prop.name, event, value, other.name))
            if event == "Next" or event == "Initial" then
              valB = value
              if updateReady() then
                return sink(event, valA and valB and valA + valB)
              end
            else
              if updateReady() then 
                return sink(event, value)
              end
            end
          end, function()
            --print(("preupdate propagating from %s to %s"):format(other.name, prop.name))
            preupdate()
          end)
        return function() unsubA(); unsubB() end
      end)
    prop.tag = "Property.Add"
    prop[1] = self
    prop[2] = other
    return prop
  end,
  __mul = function(self, other)
    return self:combine(other, mul)
  end,
  __sub = function(self, other)
    return self:combine(other, sub)
  end,
  __div = function(self, other)
    return self:combine(other, div)
  end,
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

Property.fromEventStream = fromEventStream

return Property
