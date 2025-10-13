local lcs = require("lcs")

---@class test-class.interface : lcs.interface
local test_interface = {}

function test_interface:foo()
end

lcs.interface(test_interface, "interface", { "foo" })

local instance = test_interface()
-- will throw an error since interfaces cannot be constructed

----------------------------------------------------------------
-- using interfaces
----------------------------------------------------------------

---@class test-class : lcs.class, test-class.interface
---@overload fun() : test-class
local test_class = {}

---@private
function test_class:__init()
    print("constructor")
end

function test_class:foo()
    print("foo")
end

lcs.class(test_class, "test-class", test_interface)
-- if not all interface members are implemented an error will be thrown
