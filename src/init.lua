-- required at top to be at the top of the bundled file
local configs = require("src.config")

-- to package meta in the bundled file
require("src.meta")

local utils = require("tools.utils")

local class = require("src.class")
local object_type = require("src.object")
local type_handler = require("src.type")
local members_handler = require("src.members")
local construction_handler = require("src.construction")

---@class class-system
local class_system = {}

class_system.deconstructing = configs.deconstructing
class_system.is_abstract = configs.abstract_placeholder
class_system.is_interface = configs.interface_placeholder

class_system.object_type = object_type

class_system.typeof = class.typeof
class_system.nameof = class.nameof
class_system.get_instance_data = class.get_instance_data
class_system.is_class = class.is_class
class_system.has_base = class.has_base
class_system.has_interface = class.has_interface

---@param options class-system.create.options
---@return class-system.type | nil base, table<class-system.type> interfaces
local function process_options(options)
    if type(options.name) ~= "string" then
        error("name needs to be a string")
    end

    options.is_abstract = options.is_abstract or false
    options.is_interface = options.is_interface or false

    if options.is_abstract and options.is_interface then
        error("cannot mark class as interface and abstract class")
    end

    if options.inherit then
        if class_system.is_class(options.inherit) then
            options.inherit = { options.inherit }
        end
    else
        -- could also return here
        options.inherit = {}
    end

    ---@type class-system.type, table<class-system.type>
    local base, interfaces = nil, {}
    for i, parent in ipairs(options.inherit) do
        local parentType = class_system.typeof(parent)
        ---@cast parentType class-system.type

        if options.is_abstract and (not parentType.options.is_abstract and not parentType.options.is_interface) then
            error("cannot inherit from not abstract or interface class: ".. tostring(parent) .." in an abstract class: " .. options.name)
        end

        if parentType.options.is_interface then
            interfaces[i] = class_system.typeof(parent)
        else
            if base ~= nil then
                error("cannot inherit from more than one (abstract) class: " .. tostring(parent) .. " in class: " .. options.name)
            end

            base = parentType
        end
    end

    if not options.is_interface and not base then
        base = object_type
    end

    return base, interfaces
end

---@generic TClass
---@param data TClass
---@param options class-system.create.options
---@return TClass
function class_system.create(data, options)
    options = options or {}
    local base, interfaces = process_options(options)

    local type_info = type_handler.create(base, interfaces, options)

    members_handler.sort(data, type_info)
    members_handler.check(type_info)

    utils.table.clear(data)

    construction_handler.create_template(data, type_info)

    return data
end

---@generic TClass
---@param class TClass
---@param extensions TClass
---@return TClass
function class_system.extend(class, extensions)
    if not class_system.is_class(class) then
        error("provided class is not an class")
    end

    ---@type class-system.metatable
    local metatable = getmetatable(class)
    local type_info = metatable.type

    members_handler.extend(type_info, extensions)

    return class
end

---@param obj object
function class_system.deconstruct(obj)
    ---@type class-system.metatable
    local metatable = getmetatable(obj)
    local type_info = metatable.type

    construction_handler.deconstruct(obj, metatable, type_info)
end

---@generic TClass : object
---@param name string
---@param table TClass
---@param options class-system.create.options.class.pretty | nil
---@return TClass
function _G.class(name, table, options)
    options = options or {}

    ---@type class-system.create.options
    local createOptions = {
        name = name,
        is_abstract = options.is_abstract,
        inherit = options.inherit,
    }

    return class_system.create(table, createOptions)
end

---@generic TInterface
---@param name string
---@param table TInterface
---@param options class-system.create.options.interface.pretty | nil
---@return TInterface
function _G.interface(name, table, options)
    options = options or {}

    ---@type class-system.create.options
    local createOptions = {
        name = name,
        is_interface = true,
        inherit = options.inherit,
    }

    return class_system.create(table, createOptions)
end

_G.typeof = class_system.typeof
_G.nameof = class_system.nameof

return class_system
