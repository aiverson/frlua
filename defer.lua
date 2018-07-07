--Copyright 2016-2018 Alex Iverson

return function(FR)

  function FR.defer(delay, value)
    local done = false
    local stream = FR.EventStream.fromBinder(function(sink)
        if not done then
          return FR.time.setTimeout(delay, function()
              done = true
              sink("Next", value)
              sink("End")
            end
          )
        else
          return function() end
        end
      end
    )
    stream.tag = "fr.defer"
    stream[1] = delay
    stream[2] = value
    return stream
  end

  FR.Defer = FR.defer
end
