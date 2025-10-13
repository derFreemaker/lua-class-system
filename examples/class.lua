local lcs = require("lcs")

---@class test-class.create : lcs.class
---@field value integer
---@overload fun(value: integer) : test-class.create
local test_class = {}

-- if the pre constructor returns `true` it will skip class construction and return the second returned value
-- receives the same arguments like `class:__init`
-- useful for caching instances
---@private
---@deprecated
---@return boolean
---@return any
function test_class:__pre(...)
    return false, {}
end

-- class constructor
---@private
---@deprecated
---@param value integer
function test_class:__init(value)
    self.value = value
    print("constructor")
end

-- meta method
---@private
---@deprecated
function test_class.__add(a, b)
    return test_class(a.value + b.value)
end

function test_class:foo()
    print("foo")
end

test_class.foo_value = 100

-- create class type also does all necessary checks
lcs.class(test_class, "test-class")

-- Triggers class:__init with self being set with all members added.
local instance = test_class(123)
instance:foo()

local instance2 = test_class(344)

local sum = instance + instance2
print(sum.value)
