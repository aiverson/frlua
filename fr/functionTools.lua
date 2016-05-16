--Copyright 2016 Alex Iverson

local FT = {}
local tunpack = table.unpack or unpack

function FT.createFunction(f, ...)
  local count = select("#", ...)
  if type(f) == "function" then
    if count == 0 then
      return f
    else
      local boundArgs = {...}
      return function(...)
        local newArgs = {...}
        local args = {}
        for i = 1, #boundArgs do
          args[i] = boundArgs[i]
        end
        for i = 1, #newArgs do
          args[i+count] = newArgs[i]
        end
        return f(tunpack(args))
      end
    end
  elseif type(f) == "string" then
    if string.sub(f, 1, 2) == ":" then
      local methodName = string.sub(f, 2, -1)
      f = function(obj, ...)
        return obj[methodName](obj, ...)
      end
      if count == 0 then
        return f
      else
        local boundArgs = {...}
        count = count + 1
        return function(obj, ...)
          local newArgs = {...}
          local args = {obj}
          for i = 1, #boundArgs do
            args[i+1] = boundArgs[i]
          end
          for i = 1, #newArgs do
            args[i+count] = newArgs[i]
          end
          return f(tunpack(args))
        end
      end
    elseif string.sub(f, 1, 2) == ";" then
      local methodName = string.sub(f, 2, -1)
      f = function(obj, ...)
        return obj[methodName](obj, ...)
      end
      if count == 0 then
        return f
      else
        local boundArgs = {...}
        return function(...)
          local newArgs = {...}
          local args = {}
          for i = 1, #boundArgs do
            args[i] = boundArgs[i]
          end
          for i = 1, #newArgs do
            args[i+count] = newArgs[i]
          end
          return f(tunpack(args))
        end
      end
    elseif string.sub(f, 1, 2) == "." then
      local fieldName = string.sub(f, 2, -1)
      return function(obj)
        return obj[fieldName]
      end
    elseif string.sub(f, 1, 2) == "(" then
      local funcName = string.sub(f, 2, -1)
      f = function(obj, ...)
        return obj[funcName](...)
      end
      if count == 0 then
        return f
      else
        local boundArgs = {...}
        count = count + 1
        return function(obj, ...)
          local newArgs = {...}
          local args = {obj}
          for i = 1, #boundArgs do
            args[i+1] = boundArgs[i]
          end
          for i = 1, #newArgs do
            args[i+count] = newArgs[i]
          end
          return f(tunpack(args))
        end
      end
    elseif string.sub(f, 1, 2) == "'" then
      if #f > 1 then
        local str = string.sub(f, 2, -1)
        return function() return str end
      else
        if count > 0 then
          local val = ...
          return function() return val end
        else
          return function() return "" end
        end
      end
    elseif f == "[" then
      if count == 0 then
        return function(obj, index)
          return obj[index]
        end
      else
        local index = ...
        return function(obj)
          return obj[index]
        end
      end
    elseif f == "]" then
      if count == 0 then
        return function(index, obj)
          return obj[index]
        end
      else
        local obj = ...
        return function(index)
          return obj[index]
        end
      end
    end
  else
    return function() return f end
  end
end

return FT