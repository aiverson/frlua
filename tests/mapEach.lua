--Copyright 2016 Alex Iverson

local fr = require"fr"
local test = require"tests.test"


test("double map", function(assertion)

    local push

    local stream = fr.fromBinder(function(sink)
        push = function(event, val)
          if sink(event, val) then
            push = function() end
          end
        end
        return function()
          push = function() end
        end
      end)
    local firstMap = stream:map(function(x) return x * 2 end)
    local stopPrinting = firstMap:each(assertion:expectSequenceEqual{2, 4, 6})
    push("Initial", 1)
    push("Next", 2)
    push("Next", 3)
  end):runLog()

test("table map", function(assertion)
    local stopPrinting = fr.fromTable{1, 2, 3, 4}:map(function(x) return x * 3 + 1 end):each(assertion:expectSequenceEqual{4, 7, 10, 13})
  end):runLog()

test("push plug", function(assertion)
    local bus = fr.Bus()

    bus:each(assertion:expectSequenceEqual{"test", 2, 4, 6, 1, 3, 5})

    bus:push"test"
    bus:plug(fr.fromTable{2, 4, 6})
    bus:plug(fr.fromTable{1, 3, 5})
  end):runLog()

test("table zip", function(assertion)
    fr.fromTable{1, 2, 3}:zip(fr.fromTable{4, 5, 6}, function(a, b) return a + b end):each(assertion:expectSequenceEqual{5, 7, 9})
  end):runLog()


