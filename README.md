# Lua Class System

Class System in pure lua.

Works in lua `5.3+`.

`lcs.lua` is the only file you need.

## Features

- Class
- Interface
- optional Constructor
- Meta values

## TODO

- Performance improvements

## Usage

```lua
local lcs = require('lcs')

---@class Interface : lcs.interface
local interface = {}

---@return string
function interface:greet()
end

function interface:print_greet()
    return print(self:greet())
end

lcs.interface(interface, "Interface", { "greet" })

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
    return "Hello"
end

lcs.class(class, "Class", interface)

local instance = class("Hello")
instance:print_greet()
```

### NOTE

All meta method/value names can be configured.

## Third Party (only for testing)

- [LuaAssert](https://github.com/Olivine-Labs/luassert)
- [busted](https://github.com/Olivine-Labs/busted)
