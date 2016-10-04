--Copyright 2016 Alex Iverson

local tunpack = table.unpack or unpack
local tremove = table.remove
local tinsert = table.insert

local funcTools = require"fr.functionTools"

local createFunction = funcTools.createFunction

local EventStreamMetatable

local function fromBinder(binder)
  local subscribers = {}
  local nSubscribers = 0
  local unsub
  local function sink(...)
    local i = 1
    while i <= nSubscribers do
      local finished = subscribers[i](...)
      if finished then
        tremove(subscribers, i)
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
  local newStream = {
    subscribe = function(self, other)
      tinsert(subscribers, other)
      nSubscribers = nSubscribers + 1
      if not unsub then
        unsub = binder(sink)
      end
      return function()
        for i=1, #subscribers do
          if subscribers[i] == other then
            tremove(subscribers, i)
            nSubscribers = nSubscribers - 1
            return
          end
        end
      end
    end
  }
  setmetatable(newStream, EventStreamMetatable)
  return newStream
end

local function fromCallback(f, ...)
  local args = {...}
  local nArgs = select("#", ...)
  return fromBinder(function(sink)
      args[nArgs + 1] = function(...) sink("Next", ...) end
      f(unpack(args))
      return function() end
    end)
end


local function zipBuffer(argsTab, hasArg, buffers, bufLens, index, err, value)
  if hasArg[index] then
    tinsert(buffers[index], value)
    bufLens[index] = bufLens[index] + 1
    return false
  else
    argsTab[index] = value
    hasArg[index] = true
    for i=1, #hasArg do
      if not hasArg[i] then
        return false
      end
    end
    return true
  end
end

local function zipDebuffer_internal(argsTab, hasArg, buffers, bufLens, ...)
  for i=1, #hasArg do
    if bufLens[i] > 0 then
      argsTab[i] = tremove(buffers[i], 1)
      hasArg[i] = true
      bufLens[i] = bufLens[i] - 1
    else
      argsTab[i] = nil
      hasArg[i] = false
    end
  end
  return ...
end

local function zipDebuffer(argsTab, hasArg, buffers, bufLens)
  return zipDebuffer_internal(argsTab, hasArg, buffers, bufLens, tunpack(argsTab))
end

local EventStream = {
  map = function(self, f, ...)
    local mapFunc = createFunction(f, ...)
    return fromBinder(function(sink)
        return self:subscribe(function(event, ...)
            if event == "Next" or event == "Initial" then
              return sink(event, mapFunc(...))
            else
              return sink(event, ...)
            end
          end)
      end)
  end,
  mapError = function(self, f, ...)
    local mapFunc = createFunction(f, ...)
    return fromBinder(function(sink)
        return self:subscribe(function(event, ...)
            if event == "Error" then
              return sink("Next", mapFunc(...))
            else
              return sink(event, ...)
            end
          end)
      end)
  end,
  Not = function(self)
    return self:map(function(val) return not val end)
  end,
  pmap = function(self, f, ...)
    local mapFunc = createFunction(f, ...)
    local function handleResults(event, success, ...)
      if success then
        return event, ...
      else
        return "Error", ...
      end
    end
    return fromBinder(function(sink)
        return self:subscribe(function(event, ...)
            if event == "Next" or event == "Initial" then
              return sink(handleResults(event, pcall(mapFunc, ...)))
            else
              return sink(event, ...)
            end
          end)
      end)
  end,
  onValue = function(self, f, ...)
    local eachFunc = createFunction(f, ...)
    return self:subscribe(function(event, ...)
        if event == "Next" or event == "Initial" then
          return eachFunc(...)
        else
          return false
        end
      end)
  end,
  onError = function(self, f, ...)
    local errFunc = createFunction(f, ...)
    return self:subscribe(function(event, ...)
        if event == "Error" then
          return errFunc(...)
        else
          return false
        end
      end)
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
      end)
  end,
  skipDuplicates = function(self, eql)
    local prev
    if eql then
      return fromBinder(function(sink)
          return self:subscribe(function(event, ...)
              if event == "Next" then
                if eql(..., prev) then
                  return false
                else
                  prev = ...
                  return sink(event, ...)
                end
              elseif event == "Initial" then
                prev = ...
              else
                return sink(event, ...)
              end
            end)
        end)
    else
      return fromBinder(function(sink)
          return self:subscribe(function(event, ...)
              if event == "Next" then
                if ... == prev then
                  return false
                else
                  prev = ...
                  return sink(event, ...)
                end
              elseif event == "Initial" then
                prev = ...
              else
                return sink(event, ...)
              end
            end)
        end)
    end
  end,
  filter = function(self, f, ...)
    local filterFunc = createFunction(f, ...)
    if filterFunc == nil then
      filterFunc = function(val) return val end
    end
    return fromBinder(function(sink)
        return self:subscribe(function(event, ...)
            if event == "Next" or event == "Initial" then
              if filterFunc(...) then
                return sink(event, ...)
              else
                return false
              end
            else
              sink(event, ...)
            end
          end)
      end)
  end,
  flatMap = function(self, f, ...)
    local mapFunc = createFunction(f, ...)
    local childDeps = {}
    local unsub
    local done = false
    local function streamHandler(sink, stream)
      return function(event, value)
        if event == "End" then
          if childDeps[stream] then
            childDeps[stream]()
            childDeps[stream] = nil
            if not next(childDeps) and done then
              sink(event, value)
            end
          else
            childDeps[stream] = nil
            if not next(childDeps) and done then
              sink(event, value)
            end
            return false
          end
        else
          sink(event, value)
        end
      end
    end
    return fromBinder(
      function(sink)
        for k, v in pairs(childDeps) do
          if v == false then
            childDeps[k] = k:subscribe(
              streamHandler(sink, k)
            )
          end
        end

        unsub = self:subscribe(
          function(event, value)
            if event == "Next" or event == "Initial" then
              local newStream = mapFunc(value)
              childDeps[newStream] = false
              childDeps[newStream] = newStream:subscribe(
                streamHandler(sink, newStream)
              )
            elseif event == "Error" then
              sink(event, value)
            elseif event == "End" then
              if not next(childDeps) then
                done = true
              else
                sink(event, value)
              end
            end
          end
        )
        return function()
          unsub()
          for k, v in pairs(childDeps) do
            v()
          end
        end
      end
    )

  end,
  zip = function(self, other, f, ...)
    local zipFunc = createFunction(f, ...)
    local argsTab = {nil, nil}
    local hasArg = {false, false}
    local buffer = {{}, {}}
    local buffLens = {0, 0}
    local unsub
    return fromBinder(function(sink)
        local unsubA = self:subscribe(function(event, value)
            if event == "Next" or event == "Initial" then
              if zipBuffer(argsTab, hasArg, buffer, buffLens, 1, false, value) then
                if sink("Next", zipFunc(zipDebuffer(argsTab, hasArg, buffer, buffLens))) then
                  unsub()
                  return true
                end
              else
                return false
              end
            end
          end)
        local unsubB = other:subscribe(function(event, value)
            if event == "Next" or event == "Initial" then
              if zipBuffer(argsTab, hasArg, buffer, buffLens, 2, false, value) then
                if sink("Next", zipFunc(zipDebuffer(argsTab, hasArg, buffer, buffLens))) then
                  unsub()
                  return true
                end
              else
                return false
              end
            end
          end)
        function unsub() unsubA(); unsubB(); end
        return function() unsub() end
      end)
  end
}

EventStream.each = EventStream.onValue

EventStream.fromBinder = fromBinder

function EventStream.create(subscribe)
  return setmetatable({subscribe=subscribe}, EventStreamMetatable)
end

EventStream.fromCallback = fromCallback

EventStreamMetatable = {
  __index = EventStream,
  __type = "fr.eventStream"
}

function EventStream.isEventStream(obj)
  return getmetatable(obj) == EventStreamMetatable
end

return EventStream