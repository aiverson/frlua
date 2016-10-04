--Copyright 2016 Alex Iverson
--This file manages the timer polyfill.
--Since lua doesn't have setTimeout and setInterval, but several third party libraries provide these capabilities,
--this file is needed to provide a consistent api to them all.
--To extend this with an application specific set of time functions, just provide a package "fr.time.user".
--The time package is expected to provide getTime, setTimeout, and setInterval.
--getTime is a function that will return a number representing the current time in the units of choice, probably milliseconds.
--it should be monotonic and accurate, but doesn't need to have any specific epoch.
--setTimeout and setInterval both accept a number representing a duration and a callback.
--setTimeout will call the callback once when the duration has expired.
--setInterval will call the callback repeatedly every time the duration passes.
--both should return a function that will cancel the action.
--if setInterval is not provided, it will be constructed for setTimeout. This is probably less efficient then implementing it manually.

local function configureTime(time)
  time.needTimeout = function()
    error("setTimeout is unsupported on the current configuration. Please install one of the optional dependencies (async, luvit) that provides it, or provide a custom implementation in \"fr.time.user\"")
  end
  time.needInterval = function()
    error("setInterval is unsupported on the current configuration. Please install one of the optional dependencies (async, luvit) that provides it, or provide a custom implementation in \"fr.time.user\"")
  end
  time.needGet = function()
    error("getTime is unsupported on the current configuration. Please install one of the optional dependencies (luaposix) that provides it, or provide a custom implementation in \"fr.time.user\"")
  end
  time.needGetOrTimeout = function()
    error("Either getTime or setTimeout is needed, but neither is available. Please provide one of the optional dependencies (async, luvit, luaposix) or provide an implementation in \"fr.time.user\"")
  end
  if time.setTimeout then
    time.hasTimeout = true
  else
    time.hasTimeout = false
    time.setTimeout = time.needTimeout
  end
  if time.setInterval then
    time.hasInterval = true
  else
    time.hasInterval = false
    time.setInterval = time.needInterval
  end
  if time.getTime then
    time.hasGet = true
  else
    time.hasGet = false
    time.getTime = time.needGet
  end
  return time
end

local ok, time = pcall(require, "fr.time.user")

if ok then
  if time.setTimeout and not time.setInterval then
    function time.setInterval(interval, func)
      local done = false
      local cancel
      local reset = function()
        func()
        if not done then
          cancel = time.setTimeout(interval, reset)
        end
      end
      cancel = time.setTimeout(interval, reset)
      return function()
        cancel()
        done = true
      end
    end
  end
  return configureTime(time)
end

time = {}

local timer
ok, timer = pcall(require, "fr.time.async")

if not ok then
  ok, timer = pcall(require, "fr.time.luvit")
end

if not ok then
  ok, timer = pcall(require, "fr.time.luv")
end

if ok then
  time.setTimeout = timer.setTimeout
  time.setInterval = timer.setInterval
end

ok, timer = pcall(require, "fr.time.posix")

if ok then
  time.getTime = timer.getTime
end

return configureTime(time)