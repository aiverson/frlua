--Copyright 2016 Alex Iverson

local function build(FR)

  function FR.once(value)
    local published = false
    return FR.EventStream.create(function(self, other)
        if not published then
          published = true
          if not other("Next", value) then
            other("End")
          end
        else
          other("End")
        end
        return function() end
      end)
  end
  
  FR.Once = FR.once
end

return build