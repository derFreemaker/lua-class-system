local utils = require("tools.utils")

local config = require("src.config")

local instance_handler = require("src.instance")
local metatable_handler = require("src.metatable")

---@class class-system.construction_handler
local construction_handler = {}

---@param obj object
---@return class-system.instance instance
local function construct(obj, ...)
    ---@type class-system.metatable
    local metatable = getmetatable(obj)
    local type_info = metatable.type

    if type_info.options.is_abstract then
        error("cannot construct abstract class: " .. type_info.name)
    end
    if type_info.options.is_interface then
        error("cannot construct interface class: " .. type_info.name)
    end

    if type_info.has_pre_constructor then
        local result = type_info.meta_methods.__preinit(...)
        if result ~= nil then
            return result
        end
    end

    local class_instance, class_metatable = {}, {}
    ---@cast class_instance class-system.instance
    ---@cast class_metatable class-system.metatable
    class_metatable.instance = class_instance
    local instance = setmetatable({}, class_metatable)

    instance_handler.initialize(class_instance)
    metatable_handler.create(type_info, class_instance, class_metatable)
    construction_handler.construct(type_info, instance, class_instance, class_metatable, ...)

    instance_handler.add(type_info, instance)

    return instance
end

---@param data table
---@param type_info class-system.type
function construction_handler.create_template(data, type_info)
    local metatable = metatable_handler.create_template_metatable(type_info)
    metatable.__call = construct

    setmetatable(data, metatable)

    if not type_info.options.is_abstract and not type_info.options.is_interface then
        type_info.blueprint = data
    end
end

---@param type_info class-system.type
---@param class table
local function invoke_deconstructor(type_info, class)
    if type_info.has_close then
        type_info.meta_methods.__close(class, config.deconstructing)
    end
    if type_info.has_deconstructor then
        type_info.meta_methods.__gc(class)

        if type_info.base then
            invoke_deconstructor(type_info.base, class)
        end
    end
end

---@param type_info class-system.type
---@param obj object
---@param instance class-system.instance
---@param metatable class-system.metatable
---@param ... any
function construction_handler.construct(type_info, obj, instance, metatable, ...)
    ---@type function
    local super = nil

    local function constructMembers()
        for key, value in pairs(type_info.meta_methods) do
            if not utils.table.contains_key(config.indirect_meta_methods, key) and not utils.table.contains_key(metatable, key) then
                metatable[key] = value
            end
        end

        for key, value in pairs(type_info.members) do
            if obj[key] == nil then
                rawset(obj, key, utils.value.copy(value))
            end
        end

        for _, interface in pairs(type_info.interfaces) do
            for key, value in pairs(interface.meta_methods) do
                if not utils.table.contains_key(config.indirect_meta_methods, key) and not utils.table.contains_key(metatable, key) then
                    metatable[key] = value
                end
            end

            for key, value in pairs(interface.members) do
                if not utils.table.contains_key(obj, key) then
                    obj[key] = value
                end
            end
        end

        metatable.__gc = function(class)
            invoke_deconstructor(type_info, class)
        end

        setmetatable(obj, metatable)
    end

    local base_constructed = false
    if type_info.base then
        if type_info.base.has_constructor then
            function super(...)
                constructMembers()
                construction_handler.construct(type_info.base, obj, instance, metatable, ...)
                base_constructed = true
                return obj
            end
        else
            constructMembers()
            construction_handler.construct(type_info.base, obj, instance, metatable)
            base_constructed = true
        end
    else
        constructMembers()
        base_constructed = true
    end

    if type_info.has_constructor then
        if super then
            type_info.meta_methods.__init(obj, super, ...)
        else
            type_info.meta_methods.__init(obj, ...)
        end
    end

    if not base_constructed then
        error("'" .. type_info.name ..  "' constructor did not invoke '" .. type_info.base.name .. "' (base) constructor")
    end

    instance.is_constructed = true
end

---@param obj object
---@param metatable class-system.metatable
---@param type_info class-system.type
function construction_handler.deconstruct(obj, metatable, type_info)
    instance_handler.remove(type_info, obj)
    invoke_deconstructor(type_info, obj)

    utils.table.clear(obj)
    utils.table.clear(metatable)

    local function blockedNewIndex()
        error("cannot assign values to deconstruct class: " .. type_info.name, 2)
    end
    metatable.__newindex = blockedNewIndex

    local function blockedIndex()
        error("cannot get values from deconstruct class: " .. type_info.name, 2)
    end
    metatable.__index = blockedIndex

    setmetatable(obj, metatable)
end

return construction_handler
