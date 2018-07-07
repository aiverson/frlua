local testNames = {
  "atomicProperty.lua",
  "debounce.lua",
  "mapEach.lua",
  "propertyCombine.lua"
}

local tests = {}

for i, name in ipairs(testNames) do
  tests[i] = loadfile("tests/"..name)
end

for i, test in ipairs(tests) do
  io.write("Running tests ", testNames[i], "\n")
  test()
end
