local PriorityQueue = require './PriorityQueue'

local function initialize(parent, nowtime)
  if not nowtime then nowtime = 0 end
  
  local time = {}
  local Q = PriorityQueue()
  local immediates = {}
  local barriers = 0
  
  function time.now()
    return nowtime
  end
  
  local handle_defer
  local is_deferred = false
  
  local function handle_event()
    is_deferred = false
    if #immediates > 0 then
      local imms = immediates
      immediates = {}
      for i = 1, #imms do
        imms[i]()
      end
      handle_defer()
    elseif barriers == 0 and #Q > 0 then
      local f
      f, nowtime = Q:pop()
      f()
    end
  end
  
  function handle_defer()
    if is_deferred then
      return
    end
    if #immediates > 0 or #Q > 0 and barriers == 0 then
      is_deferred = true
      parent.setImmediate(handle_event)
    end
  end
  
  function time.setImmediate(func)
    immediates[#immediates + 1] = func
    handle_defer()
  end
  
  function time.setTimeout(timeout, callback)
    local elem = Q:insert(nowtime + timeout, callback)
    return function() Q:remove(elem) end
  end
  
  function time.setInterval(interval, callback)
    local elem
    local function remove()
      Q:remove(elem)
    end
    local function doInterval()
      Q:insert(interval, doInterval)
      callback()
    end
    Q:insert(interval, doInterval)
    return remove
  end
  
  function time.barrier()
    barriers = barriers+1
    local startTime = parent.now()
    return function(duration)
      if not duration then duration = parent.now() - startTime end
      --TODO: Handle duration maybe?
      barriers = barriers - 1
    end
  end
  
  function time.withBarrier(func)
    local bar = time.barrier()
    func()
    bar()
  end
  
  return time
end

return initialize