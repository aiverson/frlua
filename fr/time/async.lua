

local asyncTime = require"async.time"

local time = {}

function time.setTimeout(timeout, callback)
  local timer = asyncTime.setTimeout(timeout, callback)
  return function()
    timer.clear()
  end
end

function time.setInterval(timeout, callback)
  local timer = asyncTime.setInterval(timeout, callback)
  return function()
    timer.clear()
  end
end

return time