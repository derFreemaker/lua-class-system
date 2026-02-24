local lcs = require('lcs')

---@class Interface : lcs.interface
local interface = {}

---@return string
function interface:greet()
    return lcs.interface_method()
end

function interface:print_greet()
    return print(self:greet())
end

lcs.interface(interface, "Interface", { interface.greet })

---@class Class : lcs.class, Interface
---@overload fun(name: string) : Class
local class = {}

---@private -- remove as much as possible from suggestions
---@deprecated -- make it more visual we cannot call this function ourself
---@param name string
function class:__init(name) -- constructor
    self.name = name
end

function class:greet()
    return self.name
end

lcs.class(class, "Class", interface)

local instance = class("Hello")
instance:print_greet()
