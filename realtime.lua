--Copyright 2016-2018 Alex Iverson
--This file implements the timing primitives for frlua
--The time package is expected to provide getTime, setTimeout, and setInterval.
--now is a function that will return a number representing the current time.
--it should be monotonic and accurate, but doesn't need to have any specific epoch.
--setTimeout and setInterval both accept a number representing a duration and a callback.
--setTimeout will call the callback once when the duration has expired.
--setInterval will call the callback repeatedly every time the duration passes.
--both should return a function that will cancel the action.
--Parts of this implementation are copied from luvit/timer.lua

local uv = require "uv"

local time = {}

function time.setTimeout(timeout, callback)
  local timer = uv.new_timer()
  local done = false
  timer:start(timeout, 0, function()
      timer:close()
      done = true
      callback()
    end
  )
  return function()
    if not done then
      timer:stop()
      timer:close()
    end
  end
end

function time.setInterval(timeout, callback)
  local timer = uv.new_timer()
  timer:start(timeout, timeout, callback)
  return function()
    timer:stop()
    timer:close()
  end
end

time.now = uv.now

local idle = uv.new_idle()
local immediates = {}

local function resolveImmediates()
  local queue = immediates
  immediates = {}
  for i = 1, #queue do
    queue[i]()
  end
  if #immediates == 0 then
    uv.idle_stop(idle)
  end
end

function time.setImmediate(callback)
  if #immediates == 0 then
    uv.idle_start(idle)
  end
  immediates[#immediates+1] = callback
end

function time.sleep(duration)
  local coro = coroutine.running()
  timer.setTimeout(duration, function()
      assert(coroutine.resume(coro))
    end)
  coroutine.yield()
end

function time.yield()
  local coro = coroutine.running()
  timer.setImmediate(function()
      assert(coroutine.resume(coro))
    end)
  coroutine.yield()
end

return time