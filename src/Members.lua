local utils = require("tools.utils")

local config = require("src.config")

local instance_handler = require("src.instance")

---@class class-system.members_handler
local members_handler = {}

---@param type_info class-system.type
function members_handler.update_state(type_info)
    local meta_methods = type_info.meta_methods

    type_info.has_pre_constructor = meta_methods.__preinit ~= nil
    type_info.has_constructor = meta_methods.__init ~= nil
    type_info.has_deconstructor = meta_methods.__gc ~= nil
    type_info.has_close = meta_methods.__close ~= nil
    type_info.has_index = meta_methods.__index ~= nil
    type_info.has_new_index = meta_methods.__newindex ~= nil
end

---@param type_info class-system.type
---@param key string
function members_handler.get_static(type_info, key)
    return rawget(type_info.static, key)
end

---@param type_info class-system.type
---@param key string
---@param value any
---@return boolean wasFound
local function assign_static(type_info, key, value)
    if rawget(type_info.static, key) ~= nil then
        rawset(type_info.static, key, value)
        return true
    end

    if type_info.base then
        return assign_static(type_info.base, key, value)
    end

    return false
end

---@param type_info class-system.type
---@param key string
---@param value any
function members_handler.set_static(type_info, key, value)
    if not assign_static(type_info, key, value) then
        rawset(type_info.static, key, value)
    end
end

-------------------------------------------------------------------------------
-- Index & NewIndex
-------------------------------------------------------------------------------

---@param type_info class-system.type
---@return fun(obj: object, key: any) : any value
function members_handler.template_index(type_info)
    return function(obj, key)
        if type(key) ~= "string" then
            error("can only use static members in template")
            return {}
        end
        ---@cast key string

        local splittedKey = utils.string.split(key:lower(), "__")
        if utils.table.contains(splittedKey, "static") then
            return members_handler.get_static(type_info, key)
        end

        error("can only use static members in template")
    end
end

---@param type_info class-system.type
---@return fun(obj: object, key: any, value: any)
function members_handler.template_new_index(type_info)
    return function(obj, key, value)
        if type(key) ~= "string" then
            error("can only use static members in template")
            return
        end
        ---@cast key string

        local splittedKey = utils.string.split(key:lower(), "__")
        if utils.table.contains(splittedKey, "static") then
            members_handler.set_static(type_info, key, value)
            return
        end

        error("can only use static members in template")
    end
end

---@param instance class-system.instance
---@param type_info class-system.type
---@return fun(obj: object, key: any) : any value
function members_handler.instance_index(instance, type_info)
    return function(obj, key)
        if type(key) == "string" then
            ---@cast key string
            local splittedKey = utils.string.split(key:lower(), "__")
            if utils.table.contains(splittedKey, "static") then
                return members_handler.get_static(type_info, key)
            elseif utils.table.contains(splittedKey, "raw") then
                return rawget(obj, key)
            end
        end

        if type_info.has_index and instance.custom_indexing then
            return type_info.meta_methods.__index(obj, key)
        end

        return rawget(obj, key)
    end
end

---@param instance class-system.instance
---@param type_info class-system.type
---@return fun(obj: object, key: any, value: any)
function members_handler.instance_new_index(instance, type_info)
    return function(obj, key, value)
        if type(key) == "string" then
            ---@cast key string
            local splittedKey = utils.string.split(key:lower(), "__")
            if utils.table.contains(splittedKey, "static") then
                return members_handler.set_static(type_info, key, value)
            elseif utils.table.contains(splittedKey, "raw") then
                rawset(obj, key, value)
            end
        end

        if type_info.has_new_index and instance.custom_indexing then
            return type_info.meta_methods.__newindex(obj, key, value)
        end

        rawset(obj, key, value)
    end
end

-------------------------------------------------------------------------------
-- Sort
-------------------------------------------------------------------------------

---@param type_info class-system.type
---@param name string
---@param func function
local function is_normal_function(type_info, name, func)
    if utils.table.contains_key(config.all_meta_methods, name) then
        type_info.meta_methods[name] = func
        return
    end

    type_info.members[name] = func
end

---@param type_info class-system.type
---@param name string
---@param value any
local function is_normal_member(type_info, name, value)
    if type(value) == 'function' then
        is_normal_function(type_info, name, value)
        return
    end

    type_info.members[name] = value
end

---@param type_info class-system.type
---@param name string
---@param value any
local function is_static_member(type_info, name, value)
    type_info.static[name] = value
end

---@param type_info class-system.type
---@param key any
---@param value any
local function sort_member(type_info, key, value)
    if type(key) == 'string' then
        ---@cast key string

        local splittedKey = utils.string.split(key:lower(), '__')
        if utils.table.contains(splittedKey, 'static') then
            is_static_member(type_info, key, value)
            return
        end

        is_normal_member(type_info, key, value)
        return
    end

    type_info.members[key] = value
end

function members_handler.sort(data, type_info)
    for key, value in pairs(data) do
        sort_member(type_info, key, value)
    end

    members_handler.update_state(type_info)
end

-------------------------------------------------------------------------------
-- Extend
-------------------------------------------------------------------------------

---@param type_info class-system.type
---@param name string
---@param func function
local function update_methods(type_info, name, func)
    if utils.table.contains_key(type_info.members, name) then
        error("trying to extend already existing meta method: " .. name)
    end

    instance_handler.update_meta_method(type_info, name, func)
end

---@param type_info class-system.type
---@param key any
---@param value any
local function update_member(type_info, key, value)
    if utils.table.contains_key(type_info.members, key) then
        error("trying to extend already existing member: " .. tostring(key))
    end

    instance_handler.update_member(type_info, key, value)
end

---@param type_info class-system.type
---@param name string
---@param value any
local function extend_is_static_member(type_info, name, value)
    if utils.table.contains_key(type_info.static, name) then
        error("trying to extend already existing static member: " .. name)
    end

    type_info.static[name] = value
end

---@param type_info class-system.type
---@param name string
---@param func function
local function extend_is_normal_function(type_info, name, func)
    if utils.table.contains_key(config.all_meta_methods, name) then
        update_methods(type_info, name, func)
    end

    update_member(type_info, name, func)
end

---@param type_info class-system.type
---@param name string
---@param value any
local function extend_is_normal_member(type_info, name, value)
    if type(value) == 'function' then
        extend_is_normal_function(type_info, name, value)
        return
    end

    update_member(type_info, name, value)
end

---@param type_info class-system.type
---@param key any
---@param value any
local function extend_member(type_info, key, value)
    if type(key) == 'string' then
        local splittedKey = utils.string.split(key, '__')
        if utils.table.contains(splittedKey, 'Static') then
            extend_is_static_member(type_info, key, value)
            return
        end

        extend_is_normal_member(type_info, key, value)
        return
    end

    if not utils.table.contains_key(type_info.members, key) then
        type_info.members[key] = value
    end
end

---@param data table
---@param type_info class-system.type
function members_handler.extend(type_info, data)
    for key, value in pairs(data) do
        extend_member(type_info, key, value)
    end

    members_handler.update_state(type_info)
end

-------------------------------------------------------------------------------
-- Check
-------------------------------------------------------------------------------

---@private
---@param baseInfo class-system.type
---@param member string
---@return boolean
function members_handler.check_for_meta_method(baseInfo, member)
    if utils.table.contains_key(baseInfo.meta_methods, member) then
        return true
    end

    if baseInfo.base then
        return members_handler.check_for_meta_method(baseInfo.base, member)
    end

    return false
end

---@private
---@param type_info class-system.type
---@param member string
---@return boolean
function members_handler.check_for_member(type_info, member)
    if utils.table.contains_key(type_info.members, member)
        and type_info.members[member] ~= config.abstract_placeholder
        and type_info.members[member] ~= config.interface_placeholder then
        return true
    end

    if type_info.base then
        return members_handler.check_for_member(type_info.base, member)
    end

    return false
end

---@private
---@param type_info class-system.type
---@param type_infoToCheck class-system.type
function members_handler.check_abstract(type_info, type_infoToCheck)
    for key, value in pairs(type_info.meta_methods) do
        if value == config.abstract_placeholder then
            if not members_handler.check_for_meta_method(type_infoToCheck, key) then
                error(
                    type_infoToCheck.name
                    .. " does not implement inherited abstract meta method: "
                    .. type_info.name .. "." .. tostring(key)
                )
            end
        end
    end

    for key, value in pairs(type_info.members) do
        if value == config.abstract_placeholder then
            if not members_handler.check_for_member(type_infoToCheck, key) then
                error(
                    type_infoToCheck.name
                    .. " does not implement inherited abstract member: "
                    .. type_info.name .. "." .. tostring(key)
                )
            end
        end
    end

    if type_info.base and type_info.base.options.is_abstract then
        members_handler.check_abstract(type_info.base, type_infoToCheck)
    end
end

---@private
---@param type_info class-system.type
---@param type_infoToCheck class-system.type
function members_handler.check_interfaces(type_info, type_infoToCheck)
    for _, interface in pairs(type_info.interfaces) do
        for key, value in pairs(interface.meta_methods) do
            if value == config.interface_placeholder then
                if not members_handler.check_for_meta_method(type_infoToCheck, key) then
                    error(
                        type_infoToCheck.name
                        .. " does not implement inherited interface meta method: "
                        .. interface.name .. "." .. tostring(key)
                    )
                end
            end
        end

        for key, value in pairs(interface.members) do
            if value == config.interface_placeholder then
                if not members_handler.check_for_member(type_infoToCheck, key) then
                    error(
                        type_infoToCheck.name
                        .. " does not implement inherited interface member: "
                        .. interface.name .. "." .. tostring(key)
                    )
                end
            end
        end
    end

    if type_info.base then
        members_handler.check_interfaces(type_info.base, type_infoToCheck)
    end
end

---@param type_info class-system.type
function members_handler.check(type_info)
    if not type_info.options.is_abstract then
        if utils.table.contains(type_info.meta_methods, config.abstract_placeholder) then
            error(type_info.name .. " has abstract meta method/s but is not marked as abstract")
        end

        if utils.table.contains(type_info.members, config.abstract_placeholder) then
            error(type_info.name .. " has abstract member/s but is not marked as abstract")
        end
    end

    if not type_info.options.is_interface then
        if utils.table.contains(type_info.members, config.interface_placeholder) then
            error(type_info.name .. " has interface meta methods/s but is not marked as interface")
        end

        if utils.table.contains(type_info.members, config.interface_placeholder) then
            error(type_info.name .. " has interface member/s but is not marked as interface")
        end
    end

    if not type_info.options.is_abstract and not type_info.options.is_interface then
        members_handler.check_interfaces(type_info, type_info)

        if type_info.base and type_info.base.options.is_abstract then
            members_handler.check_abstract(type_info.base, type_info)
        end
    end
end

return members_handler
