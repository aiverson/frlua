local posixTime = require"posix.time"

local time = {}

local startTime = posixTime.clock_gettime(posixTime.CLOCK_MONOTONIC)

function time.getTime()
  local timespec = posixTime.clock_gettime(posixTime.CLOCK_MONOTONIC)
  local sec = timespec.tv_sec - startTime.tv_sec
  local nsec = timespec.tv_nsec - startTime.tv_nsec
  return sec * 1000 + nsec/1000/1000
end

return time