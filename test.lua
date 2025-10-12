---@type lcs
local lcs = require("class_system")

---@class test.interface : lcs.interface
local Interface = {}

---@return string
function Interface:foo()
    ---@diagnostic disable-next-line: missing-return
end

---@return string
function Interface:hi()
    return self:foo()
end

lcs.interface(Interface, "test.interface", { "foo" } --[[ , <interfaces>...]])

---@class test.class : lcs.class, test.interface
---@field test string
---@overload fun(test: string) : test.class
local Class = {}

---@private
---@deprecated
---@param test string
function Class:__init(test)
    self.test = test
end

function Class:foo()
    return self.test
end

lcs.class(Class, "test.class", Interface)

local test_class = Class("test")
print(test_class:hi())
