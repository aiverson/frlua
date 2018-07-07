--Copyright 2016-2018 Alex Iverson

return function(FR)

  function FR.isObservable(obj)
    return FR.isEventStream(obj) or FR.isProperty(obj)
  end

end