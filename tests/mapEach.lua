--Copyright 2016 Alex Iverson

local fr = require"fr"

local push

local stream = fr.fromBinder(function(sink)
    push = function(...)
      if sink(...) then
        push = function() end
      end
    end
    return function()
      push = function() end
    end
  end)

local firstMap = stream:map(function(x) return x * 2 end)
local stopPrinting = firstMap:each(print)
push("Initial", 1)
push("Next", 2)
push("Next", 3)

print()

stopPrinting = fr.fromTable{1, 2, 3, 4}:map(function(x) return x * 3 + 1 end):each(print)

local bus = fr.Bus()

bus:each(print)

bus:push"test"
bus:plug(fr.fromTable{2, 4, 6})
bus:plug(fr.fromTable{1, 3, 5})

print()

bus:plug(fr.fromTable{1, 2, 3}:zip(fr.fromTable{4, 5, 6}, function(a, b) return a + b end))

