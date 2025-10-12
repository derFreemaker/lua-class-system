----------------------------------------------------------------
-- config
----------------------------------------------------------------

---@class lcs.config
local config = {}

---@enum lcs.config.meta_type
config.meta_type = {
    pre_constructor = {},
    constructor = {},
    index = {},
    new_index = {},
    gc = {},
    close = {},
    call = {},
    pairs = {},
    to_string = {},

    add = {},
    sub = {},
    mul = {},
    div = {},
    mod = {},
    pow = {},
    neg = {},
    floor_div = {},
    bit_and = {},
    bit_or = {},
    bit_xor = {},
    bit_not = {},
    bit_shift_left = {},
    bit_shift_right = {},
    concat = {},
    len = {},
    equal = {},
    lower_than = {},
    lower_equal = {},
}

-- to deactivate a meta_methods, comment it out

---@type table<string, lcs.config.meta_type>
config.meta = {
    ["__gc"] = config.meta_type.gc,
    -- Lua >=5.4
    ["__close"] = config.meta_type.close,
    ["__call"] = config.meta_type.call,
    ["__pairs"] = config.meta_type.pairs,
    ["__tostring"] = config.meta_type.to_string,

    -- operators
    ["__add"] = config.meta_type.add,
    ["__sub"] = config.meta_type.sub,
    ["__mul"] = config.meta_type.mul,
    ["__div"] = config.meta_type.div,
    ["__mod"] = config.meta_type.mod,
    ["__pow"] = config.meta_type.pow,
    ["__unm"] = config.meta_type.neg,
    ["__idiv"] = config.meta_type.floor_div,
    ["__band"] = config.meta_type.bit_and,
    ["__bor"] = config.meta_type.bit_or,
    ["__bxor"] = config.meta_type.bit_xor,
    ["__bnot"] = config.meta_type.bit_not,
    ["__shl"] = config.meta_type.bit_shift_left,
    ["__shr"] = config.meta_type.bit_shift_right,
    ["__concat"] = config.meta_type.concat,
    ["__len"] = config.meta_type.len,
    ["__eq"] = config.meta_type.equal,
    ["__lt"] = config.meta_type.lower_than,
    ["__le"] = config.meta_type.lower_equal,
}

---@type table<string, lcs.config.meta_type>
config.indirect_meta = {
    ["__pre"] = config.meta_type.pre_constructor,
    ["__init"] = config.meta_type.constructor,
    ["__index"] = config.meta_type.index,
    ["__newindex"] = config.meta_type.new_index,
}

---@type table<lcs.config.meta_type, string>
config.reverse_meta = {}
for name, meta in pairs(config.meta) do
    config.reverse_meta[meta] = name
end

---@type table<lcs.config.meta_type, string>
config.reverse_indirect_meta = {}
for name, meta in pairs(config.indirect_meta) do
    config.reverse_indirect_meta[meta] = name
end

----------------------------------------------------------------
-- config
----------------------------------------------------------------

---@class lcs.class : function

---@class lcs.interface

---@class lcs.type
---@field name string
---
---@field interfaces lcs.type[]
---@field is_interface boolean
---@field interfacing_methods string[]?
---
---@field has_pre_constructor boolean
---@field has_constructor boolean
---
---@field meta table<lcs.config.meta_type, any>
---@field indirect_meta table<lcs.config.meta_type, any>
---
---@field members table<any, any>

---@class lcs
---@field config lcs.config
local LCS = {
    config = config
}

---@type unknown
LCS.unique_type_key = {}

---@param tbl lcs.class
---@param type_info lcs.type
---@param interfaces lcs.type[]
local function check_interfaces(tbl, type_info, interfaces)
    for _, interface in ipairs(interfaces) do
        for _, name in pairs(interface.interfacing_methods) do
            if tbl[name] == nil then
                error(("interface method '%s' not implemented in class '%s' from interface '%s'"):format(name, type_info.name, interface.name))
            end
        end

        for key in pairs(interface.members) do
            if tbl[key] ~= nil then
                error(("overriding member '%s' in class '%s' from interface '%s' is not allowed"):format(key, type_info.name, interface.name))
            end
        end

        check_interfaces(tbl, type_info, interface.interfaces)
    end
end

---@param instance lcs.class
---@param interfaces lcs.type[]
local function add_interfaces(instance, interfaces)
    for _, interface in ipairs(interfaces) do
        for name, method in pairs(interface.members) do
            instance[name] = method
        end

        add_interfaces(instance, interface.interfaces)
    end
end

---@param key any
---@param interfaces lcs.type[]
local function index_members_interfaces(key, interfaces)
    for _, interface in ipairs(interfaces) do
        local value = interface.members[key]
        if value ~= nil then
            return value
        end

        return index_members_interfaces(key, interface.interfaces)
    end
end

---@class lcs.create.options
---@field name string
---
---@field interfaces lcs.type[]?
---
---@field is_interface boolean?
---@field interfacing_methods string[]?

---@generic T : lcs.class | lcs.interface
---@param tbl T
---@param options lcs.create.options
---@return lcs.type
local function create_type(tbl, options)
    ---@type lcs.type
    local type_info = {
        name = options.name,

        interfaces = options.interfaces or {},
        is_interface = options.is_interface or false,
        interfacing_methods = options.interfacing_methods,

        has_pre_constructor = tbl[config.reverse_indirect_meta[config.meta_type.pre_constructor]] ~= nil,
        has_constructor = tbl[config.reverse_indirect_meta[config.meta_type.constructor]] ~= nil,

        meta = {},
        indirect_meta = {},

        members = {},
    }

    if options.is_interface then
        for _, interfacing_method_name in ipairs(type_info.interfacing_methods) do
            if type(tbl[interfacing_method_name]) ~= "function" then
                error(("not a valid interface method found: '%s' in type '%s'"):format(interfacing_method_name,
                    type_info.name))
            end
            tbl[interfacing_method_name] = nil
        end
    else
        if #options.interfaces > 0 then
            check_interfaces(tbl, type_info, options.interfaces)
        end
    end

    for key, value in pairs(tbl) do
        tbl[key] = nil

        local meta = config.meta[key]
        if meta ~= nil then
            if type_info.is_interface then
                error(("cannot add meta method '%s' to interface '%s'"):format(key, type_info.name))
            end

            type_info.meta[meta] = value
            goto continue
        end

        local indirect_meta = config.indirect_meta[key]
        if indirect_meta ~= nil then
            if type_info.is_interface then
                error(("cannot add indirect meta method '%s' to interface '%s'"):format(key, type_info.name))
            end

            type_info.indirect_meta[indirect_meta] = value
            goto continue
        end

        type_info.members[key] = value
        ::continue::
    end

    return type_info
end

---@param type_info lcs.type
---@return fun(...: any) : any
local function constructor(type_info)
    return function(...)
        local function get_args(_, ...)
            return ...
        end

        if type_info.has_pre_constructor then
            local pre_constructor =
                type_info.indirect_meta[config.meta_type.pre_constructor]
            local result = pre_constructor(get_args(...))
            if result ~= nil then
                return result
            end
        end

        local instance, mt = {}, {}
        setmetatable(instance, mt)
        mt[LCS.unique_type_key] = type_info

        mt.__tostring = type_info.meta[config.meta_type.to_string] or
            function()
                return ("class: %s"):format(type_info.name)
            end

        for meta, value in pairs(type_info.meta) do
            mt[config.reverse_meta[meta]] = value
        end

        for key, method in pairs(type_info.members) do
            instance[key] = method
        end

        add_interfaces(instance, type_info.interfaces)

        if type_info.has_constructor then
            type_info.indirect_meta[config.meta_type.constructor](instance, get_args(...))
        end

        return instance
    end
end

---@generic T : lcs.class | lcs.interface
---@param tbl T
---@param type_info lcs.type
---@return T
local function make_template(tbl, type_info)
    local mt = {}
    mt[LCS.unique_type_key] = type_info

    mt.__index = function(_, key)
        local value = type_info.members[key]
        if value ~= nil then
            return value
        end

        return index_members_interfaces(key, type_info.interfaces)
    end

    mt.__newindex = function(_, key, value)
        error(("cannot set value '%s' in class template '%s'"):format(key, type_info.name))
    end

    if not type_info.is_interface then
        mt.__call = constructor(type_info)
    end

    if type_info.is_interface then
        function mt:__tostring()
            return ("interface: %s"):format(type_info.name)
        end
    else
        function mt:__tostring()
            return ("template: %s"):format(type_info.name)
        end
    end

    return setmetatable(tbl, mt)
end

--- the table provided gets overridden
---@generic T : lcs.class | lcs.interface
---@param tbl T
---@param options lcs.create.options
---@return T
function LCS.create(tbl, options)
    if type(tbl) ~= "table" then
        error("#1 expected table, got " .. type(tbl))
    end

    local type_info = create_type(tbl, options)

    make_template(tbl, type_info)

    return tbl
end

---@param obj any
---@return lcs.type?
function LCS.typeof(obj)
    local mt = getmetatable(obj)
    if not mt then
        return nil
    end

    ---@type lcs.type
    local type_info = mt[LCS.unique_type_key]
    if not type_info then
        return nil
    end

    return type_info
end

---@param obj any
---@return boolean
function LCS.is_class(obj)
    local type_info = LCS.typeof(obj)
    if not type_info then
        return false
    end

    return not type_info.is_interface
end

---@param obj lcs.class
---@param class lcs.class
---@return boolean
function LCS.is_class_of(obj, class)
    local type_info = LCS.typeof(obj)
    if not type_info then
        return false
    end

    local class_info = LCS.typeof(class)
    if not type_info then
        return false
    end

    return type_info == class_info
end

---@param obj any
---@return boolean
function LCS.is_interface(obj)
    local type_info = LCS.typeof(obj)
    if not type_info then
        return false
    end

    return type_info.is_interface
end

---@param obj lcs.class
---@param interface lcs.interface
---@return boolean
function LCS.has_interface(obj, interface)
    local type_info = LCS.typeof(obj)
    if not type_info then
        return false
    end

    local interface_type = LCS.typeof(interface)
    if not type_info then
        return false
    end

    for _, implemented_type in ipairs(type_info.interfaces) do
        if implemented_type == interface_type then
            return true
        end
    end

    return false
end

---@generic T : lcs.class
---@param tbl T
---@param name string
---@param ... lcs.interface
---@return T
function LCS.class(tbl, name, ...)
    assert(type(tbl) == "table", "#1 expected table, got " .. type(tbl))
    assert(type(name) == "string", "#2 expected string, got " .. type(name))

    ---@type lcs.create.options
    local opts = {
        name = name,
        interfaces = {},
    }

    for i, interface in ipairs({ ... }) do
        if not LCS.is_interface(interface) then
            error(("not a valid interface found: '%d' in type '%s'"):format(i, name))
        end
        table.insert(opts.interfaces, LCS.typeof(interface))
    end

    return LCS.create(tbl, opts)
end

---@generic T : lcs.interface
---@param tbl T
---@param name string
---@param interfacing_methods string[]?
---@param ... lcs.interface
---@return T
function LCS.interface(tbl, name, interfacing_methods, ...)
    assert(type(tbl) == "table", "#1 expected table, got " .. type(tbl))
    assert(type(name) == "string", "#2 expected string, got " .. type(name))

    ---@type lcs.create.options
    local opts = {
        name = name,

        interfaces = {},

        is_interface = true,
        interfacing_methods = interfacing_methods or {},
    }

    for i, interface in ipairs({ ... }) do
        if not LCS.is_interface(interface) then
            error(("not a valid interface found: '%d' in type '%s'"):format(i, name))
        end
        table.insert(opts.interfaces, LCS.typeof(interface))
    end

    return LCS.create(tbl, opts)
end

return LCS
