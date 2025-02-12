package.path = "./?.lua;" .. package.path
local luaunit = require("tests.Luaunit")
local functions = require("tests.functions")
local class_system = require("src.init")

function TestBenchmarkCreateClassInstance()
    local test_class = {}
    class_system.create(test_class, { name = "test-class" })

    local function create_class()
        local instance = test_class()
    end

    functions.benchmark_function(create_class, 100000)
end

os.exit(luaunit.LuaUnit.run())
