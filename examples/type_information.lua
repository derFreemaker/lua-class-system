---@type lcs
local lcs = require("lcs")

---@class test-class.type : lcs.class
---@overload fun() : test-class.type
local test_class = {}
lcs.class(test_class, "test-class")

local type_info = lcs.typeof(test_class)
if not type_info then
    return
end

local type_name = type_info.name
-- Name of the type.

local type_has_pre_constructor = type_info.has_pre_constructor
-- Indicates if type has a pre constructor.

local type_has_constructor = type_info.has_constructor
-- Indicates if type has a __init function aka constructor.

local type_members = type_info.members
-- All members of the type.

local type_meta = type_info.meta
-- All meta related values of the type.

local type_is_interface = type_info.is_interface
-- True if type is an interface.

local type_interfacing_methods = type_info.interfacing_methods
-- all methods names which are to be implemented by a child class.

local type_interfaces = type_info.interfaces
-- All the implemented interfaces.
