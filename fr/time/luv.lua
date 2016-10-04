local uv = require "luv"

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

return time