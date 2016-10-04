local function checkTableMatch(template, value)
  for k, v in pairs(template) do
    if value[k] ~= v then
      local key
      if type(k) == "string" then
        key = ("%q"):format(k)
      else
        key = tostring(k)
      end
      return false, k, key
    end
  end
  return true
end

local test = {
  expectSequenceEqual = function(self, name, values)
    if not values then values, name = name, nil end
    local idx = #self + 1
    self[idx] = false
    local i = 1
    local max = values.n or #values
    return function(val)
      --print(val)
      if not self.failed then
        if val ~= values[i] then
          self.failed = true
          local message = "assertion"
          if name then
            message = message .. " " .. name
          end
          message = message .. " failed: expected "
          if type(values[i]) == "string" then
            message = message .. ("%q"):format(values[i])
          else
            message = message .. tostring(values[i])
          end
          message = message .. ", got "
          if type(val) == "string" then
            message = message .. ("%q"):format(val)
          else
            message = message .. tostring(val)
          end
          self.message = message
        end
        i = i + 1
      end
    end
  end,
  expectSequenceTableMatch = function(self, name, values)
    if not values then values, name = name, nil end
    local idx = #self + 1
    self[idx] = false
    local i = 1
    local max = values.n or #values
    return function(val)
      --print(val)
      if not self.failed then
        local match, k, key = checkTableMatch(values[i], val)
        if not match then
          self.failed = true
          local message = "assertion"
          if name then
            message = message .. " " .. name
          end
          message = message .. " failed: [" .. key .."] expected "
          if type(values[i][k]) == "string" then
            message = message .. ("%q"):format(values[i][k])
          else
            message = message .. tostring(values[i][k])
          end
          message = message .. ", got "
          if type(val[k]) == "string" then
            message = message .. ("%q"):format(val[k])
          else
            message = message .. tostring(val[k])
          end
          self.message = message
        end
        i = i + 1
      end
    end
  end,
  run = function(self)
    self:action()
    return self.failed, self.message
  end,
  runLog = function(self)
    self:action()
    if self.failed then
      io.write(self.name.." failed: "..self.message.."\n")
    else
      io.write(self.name.." passed\n")
    end
  end
}

local testMetatable = {
  __index = test
}

local function createTest(name, action)
  local newTest = {name = name, action = action}
  return setmetatable(newTest, testMetatable)
end

return createTest
