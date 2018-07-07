local queue = {}

--Element format: Table, first position is the priority, second is the index in the queue structure, the third is the actual value

local function swap(q, a, b)
  q[a[2]], q[b[2]], a[2], b[2] = b, a, b[2], a[2]
end

local function  percolate_down(q, index)
  local len = #q
  while 2 * index <= len do
    local thiselem, nextelem = q[index], q[2*index]
    
    if 2*index+1 <= len and q[2*index+1][1] < nextelem[1] then
      nextelem = q[2*index+1]
    end
    
    if thiselem[1] > nextelem[1] then
      swap(q, thiselem, nextelem)
    end
    index = thiselem[2]
  end
end

local function percolate_up(q, index)
  while index > 1 do
    local thiselem, nextelem = q[index], q[math.floor(index/2)]
    
    if thiselem[1] < nextelem[1] then
      swap(q, thiselem, nextelem)
    end
    index = thiselem[2]
  end
end

function queue:insert(priority, val)
  local elem = {priority, #self+1, val}
  self[elem[2]] = elem
  percolate_up(self, elem[2])
  return elem
end

function queue:pop()
  local elem = self[1]
  swap(self, 1, #self)
  self[#self] = nil
  percolate_down(self, 1)
  return elem[3], elem[1]
end

function queue:peek()
  return self[1][3], self[1][1]
end

function queue:remove(elem)
  if self[elem[2]] ~= elem then
    return
  end
  local idx = elem[2]
  swap(self, idx, #self)
  self[#self] = nil
  percolate_down(self, idx)
  return elem[3], elem[1]
end

local metatable = {
  __index = queue,
}

local function makeQueue()
  return setmetatable({}, metatable)
end

return makeQueue