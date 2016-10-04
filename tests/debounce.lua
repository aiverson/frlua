
package.path = "./?.lua;"..package.path

local userTime = {}
local luvTime = require"fr.time.luv"
userTime.setInterval = luvTime.setInterval
userTime.setTimeout = luvTime.setTimeout
local posixTime = require"fr.time.posix"
userTime.getTime = posixTime.getTime
package.loaded["fr.time.user"] = userTime

local time = require"fr.time"
local fr = require"fr"
local xlua = require"xlua"

local source = fr.fromTable{
  {0, 1},
  {5, 2},
  {6, 3},
  {7, 4},
  {10, 5},
  {17, 6},
  {20, 7},
  {100, 8}}:flatMap(function(args)
    return fr.defer(args[1], args[2])
  end
)
--[[
local source = fr.defer(5, 1):merge(
  fr.defer(6, 2)):merge(
  fr.defer(7, 3)):merge(
  fr.defer(10, 4)):merge(
  fr.defer(16, 5)):merge(
  fr.defer(20, 6))
  ]]
  
source:each(print, "source")
source:each(io.flush)
source:debounce(5):each(print, "debounce")
source:debounceImmediate(5):each(print, "debounceImmediate")
--time.setInterval(50, io.flush)


require"luv".run()