local luvitTime = require"timer"

local time = {}

function time.setTimeout(timeout, callback)
  local timer = luvitTime.setTimeout(timeout, callback)
  return function()
    luvitTime.clearTimer(timer)
  end
end

function time.setInterval(timeout, callback)
  local timer = luvitTime.setInterval(timeout, callback)
  return function()
    luvitTime.clearTimer(timer)
  end
end

return time