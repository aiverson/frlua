--Copyright 2016 Alex Iverson

local function build(FR)

  function FR.fromTable(tab, delay)
    if not delay then
      local published = false
      return FR.EventStream.create(function(self, other)
          if not published then
            published = true
            for i=1, #tab do
              local finished = other("Next", tab[i])
              if finished then
                return
              end
            end
            other("End")
          else
            other("End")
          end
          return function() end
        end)
    else
      local i = 1
      local subscribing = false
      return FR.EventStream.fromBinder(function(sink)
          local function update()
            if subscribing then
              if i <= #tab then
                sink("Next", tab[i])
                i = i + 1
                time.setImmediate(update)
              else
                sink("End")
              end
            end
          end
          subscribing = true
          time.setImmediate(update)
          return function()
            subscribing = false
          end
        end)
    end
  end
end

return build