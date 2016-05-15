local eventStream = require"fr.EventStream"

local function fromTable(tab)
  local published = false
  return eventStream.create(function(self, other)
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
end

return fromTable