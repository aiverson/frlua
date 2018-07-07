--Copyright 2016 Alex Iverson

return function(FR)

  function FR.never()
    return FR.EventStream.create(function(self, other)
        other("End")
        return function() end
      end)
  end
  
  FR.Never = FR.never
end