---@diagnostic disable

	local __bundler__ = {
	    __files__ = {},
	    __binary_files__ = {},
	    __cache__ = {},
	    __temp_files__ = {},
	    __org_exit__ = os.exit
	}
	function __bundler__.__get_os__()
	    if package.config:sub(1, 1) == '\\' then
	        return "windows"
	    else
	        return "linux"
	    end
	end
	function __bundler__.__loadFile__(module)
	    if not __bundler__.__cache__[module] then
	        if __bundler__.__binary_files__[module] then
	        local tempDir = os.getenv("TEMP") or os.getenv("TMP")
	            if not tempDir then
	                tempDir = "/tmp"
	            end
	            local os_type = __bundler__.__get_os__()
	            local file_path = tempDir .. os.tmpname()
	            local file = io.open(file_path, "wb")
	            if not file then
	                error("unable to open file: " .. file_path)
	            end
	            local content
	            if os_type == "windows" then
	                content = __bundler__.__files__[module .. ".dll"]
	            else
	                content = __bundler__.__files__[module .. ".so"]
	            end
	            local content_len = content:len()
	            for i = 2, content_len, 2 do
	                local byte = tonumber(content:sub(i - 1, i), 16)
	                file:write(string.char(byte))
	            end
	            file:close()
	            __bundler__.__cache__[module] = { package.loadlib(file_path, "luaopen_" .. module)() }
	            table.insert(__bundler__.__temp_files__, file_path)
	        else
	            __bundler__.__cache__[module] = { __bundler__.__files__[module]() }
	        end
	    end
	    return table.unpack(__bundler__.__cache__[module])
	end
	function __bundler__.__cleanup__()
	    for _, file_path in ipairs(__bundler__.__temp_files__) do
	        os.remove(file_path)
	    end
	end
	---@diagnostic disable-next-line: duplicate-set-field
	function os.exit(...)
	    __bundler__.__cleanup__()
	    __bundler__.__org_exit__(...)
	end
	function __bundler__.__main__()
	    local loading_thread = coroutine.create(__bundler__.__loadFile__)
	    local success, items = (function(success, ...) return success, {...} end)
	        (coroutine.resume(loading_thread, "__main__"))
	    if not success then
	        print("error in bundle loading thread:\n"
	            .. debug.traceback(loading_thread, items[1]))
	    end
	    __bundler__.__cleanup__()
	    return table.unpack(items)
	end
	__bundler__.__files__["src.config"] = function()
	---@class class-system.configs
	local configs = {}

	--- All meta methods that should be added as meta method to the class.
	configs.all_meta_methods = {
	    --- Before Constructor
	    __preinit = true,
	    --- Constructor
	    __init = true,
	    --- Garbage Collection
	    __gc = true,
	    --- Out of Scope
	    __close = true,

	    --- Special
	    __call = true,
	    __newindex = true,
	    __index = true,
	    __pairs = true,
	    __ipairs = true,
	    __tostring = true,

	    -- Operators
	    __add = true,
	    __sub = true,
	    __mul = true,
	    __div = true,
	    __mod = true,
	    __pow = true,
	    __unm = true,
	    __idiv = true,
	    __band = true,
	    __bor = true,
	    __bxor = true,
	    __bnot = true,
	    __shl = true,
	    __shr = true,
	    __concat = true,
	    __len = true,
	    __eq = true,
	    __lt = true,
	    __le = true
	}

	--- Blocks meta methods on the blueprint of an class.
	configs.block_meta_methods_on_blueprint = {
	    __pairs = true,
	    __ipairs = true
	}

	--- Blocks meta methods if not set by the class.
	configs.block_meta_methods_on_instance = {
	    __pairs = true,
	    __ipairs = true
	}

	--- Meta methods that should not be set to the classes metatable, but remain in the type.MetaMethods.
	configs.indirect_meta_methods = {
	    __preinit = true,
	    __gc = true,
	    __index = true,
	    __newindex = true
	}

	-- Indicates that the __close method is called from the ClassSystem.Deconstruct method.
	configs.deconstructing = {}

	-- Placeholder is used to indicate that this member should be set by super class of the abstract class
	---@type any
	configs.abstract_placeholder = {}

	-- Placeholder is used to indicate that this member should be set by super class of the interface
	---@type any
	configs.interface_placeholder = {}

	return configs

end

__bundler__.__files__["src.meta"] = function()
	---@meta

	----------------------------------------------------------------
	-- MetaMethods
	----------------------------------------------------------------

	---@class class-system.object-meta-methods
	---@field protected __preinit (fun(...) : any) | nil self(...) before contructor
	---@field protected __init (fun(self: object, ...)) | nil self(...) constructor
	---@field protected __call (fun(self: object, ...) : ...) | nil self(...) after construction
	---@field protected __close (fun(self: object, errObj: any) : any) | nil invoked when the object gets out of scope
	---@field protected __gc fun(self: object) | nil class-system.deconstruct(self) or on garbageCollection
	---@field protected __add (fun(self: object, other: any) : any) | nil (self) + (value)
	---@field protected __sub (fun(self: object, other: any) : any) | nil (self) - (value)
	---@field protected __mul (fun(self: object, other: any) : any) | nil (self) * (value)
	---@field protected __div (fun(self: object, other: any) : any) | nil (self) / (value)
	---@field protected __mod (fun(self: object, other: any) : any) | nil (self) % (value)
	---@field protected __pow (fun(self: object, other: any) : any) | nil (self) ^ (value)
	---@field protected __idiv (fun(self: object, other: any) : any) | nil (self) // (value)
	---@field protected __band (fun(self: object, other: any) : any) | nil (self) & (value)
	---@field protected __bor (fun(self: object, other: any) : any) | nil (self) | (value)
	---@field protected __bxor (fun(self: object, other: any) : any) | nil (self) ~ (value)
	---@field protected __shl (fun(self: object, other: any) : any) | nil (self) << (value)
	---@field protected __shr (fun(self: object, other: any) : any) | nil (self) >> (value)
	---@field protected __concat (fun(self: object, other: any) : any) | nil (self) .. (value)
	---@field protected __eq (fun(self: object, other: any) : any) | nil (self) == (value)
	---@field protected __lt (fun(t1: any, t2: any) : any) | nil (self) < (value)
	---@field protected __le (fun(t1: any, t2: any) : any) | nil (self) <= (value)
	---@field protected __unm (fun(self: object) : any) | nil -(self)
	---@field protected __bnot (fun(self: object) : any) | nil  ~(self)
	---@field protected __len (fun(self: object) : any) | nil #(self)
	---@field protected __pairs (fun(t: table) : ((fun(t: table, key: any) : key: any, value: any), t: table, startKey: any)) | nil pairs(self)
	---@field protected __ipairs (fun(t: table) : ((fun(t: table, key: number) : key: number, value: any), t: table, startKey: number)) | nil ipairs(self)
	---@field protected __tostring (fun(t):string) | nil tostring(self)
	---@field protected __index (fun(class, key) : any) | nil xxx = self.xxx | self[xxx]
	---@field protected __newindex fun(class, key, value) | nil self.xxx = xxx | self[xxx] = xxx

	---@class object : class-system.object-meta-methods, function

	---@class class-system.meta-methods
	---@field __gc fun(self: object) | nil class-system.Deconstruct(self) or garbageCollection
	---@field __close (fun(self: object, errObj: any) : any) | nil invoked when the object gets out of scope
	---@field __call (fun(self: object, ...) : ...) | nil self(...) after construction
	---@field __index (fun(class: object, key: any) : any) | nil xxx = self.xxx | self[xxx]
	---@field __newindex fun(class: object, key: any, value: any) | nil self.xxx | self[xxx] = xxx
	---@field __tostring (fun(t):string) | nil tostring(self)
	---@field __add (fun(left: any, right: any) : any) | nil (left) + (right)
	---@field __sub (fun(left: any, right: any) : any) | nil (left) - (right)
	---@field __mul (fun(left: any, right: any) : any) | nil (left) * (right)
	---@field __div (fun(left: any, right: any) : any) | nil (left) / (right)
	---@field __mod (fun(left: any, right: any) : any) | nil (left) % (right)
	---@field __pow (fun(left: any, right: any) : any) | nil (left) ^ (right)
	---@field __idiv (fun(left: any, right: any) : any) | nil (left) // (right)
	---@field __band (fun(left: any, right: any) : any) | nil (left) & (right)
	---@field __bor (fun(left: any, right: any) : any) | nil (left) | (right)
	---@field __bxor (fun(left: any, right: any) : any) | nil (left) ~ (right)
	---@field __shl (fun(left: any, right: any) : any) | nil (left) << (right)
	---@field __shr (fun(left: any, right: any) : any) | nil (left) >> (right)
	---@field __concat (fun(left: any, right: any) : any) | nil (left) .. (right)
	---@field __eq (fun(left: any, right: any) : any) | nil (left) == (right)
	---@field __lt (fun(left: any, right: any) : any) | nil (left) < (right)
	---@field __le (fun(left: any, right: any) : any) | nil (left) <= (right)
	---@field __unm (fun(self: object) : any) | nil -(self)
	---@field __bnot (fun(self: object) : any) | nil ~(self)
	---@field __len (fun(self: object) : any) | nil #(self)
	---@field __pairs (fun(self: object) : ((fun(t: table, key: any) : key: any, value: any), t: table, startKey: any)) | nil pairs(self)
	---@field __ipairs (fun(self: object) : ((fun(t: table, key: number) : key: number, value: any), t: table, startKey: number)) | nil ipairs(self)

	---@class class-system.type-meta-methods : class-system.meta-methods
	---@field __preinit (fun(...) : any) | nil self(...) before constructor
	---@field __init (fun(self: object, ...)) | nil self(...) constructor

	----------------------------------------------------------------
	-- Type
	----------------------------------------------------------------

	---@class class-system.type
	---@field name string
	---
	---@field base class-system.type | nil
	---@field interfaces table<integer, class-system.type>
	---
	---@field static table<string, any>
	---
	---@field meta_methods class-system.type-meta-methods
	---@field members table<any, any>
	---
	---@field has_pre_constructor boolean
	---@field has_constructor boolean
	---@field has_deconstructor boolean
	---@field has_close boolean
	---@field has_index boolean
	---@field has_new_index boolean
	---
	---@field options class-system.type.options
	---
	---@field instances table<object, boolean>
	---
	---@field blueprint table | nil

	---@class class-system.type.options
	---@field is_abstract boolean | nil
	---@field is_interface boolean | nil

	----------------------------------------------------------------
	-- Metatable
	----------------------------------------------------------------

	---@class class-system.metatable : class-system.meta-methods
	---@field type class-system.type
	---@field instance class-system.instance

	----------------------------------------------------------------
	-- Blueprint
	----------------------------------------------------------------

	---@class class-system.blueprint-metatable : class-system.meta-methods
	---@field type class-system.type

	----------------------------------------------------------------
	-- Instance
	----------------------------------------------------------------

	---@class class-system.instance
	---@field is_constructed boolean
	---
	---@field custom_indexing boolean

	----------------------------------------------------------------
	-- Create Options
	----------------------------------------------------------------

	---@class class-system.create.options : class-system.type.options
	---@field name string | nil
	---
	---@field inherit object[] | object | nil

	---@class class-system.create.options.class.pretty
	---@field is_abstract boolean | nil
	---
	---@field inherit any | any[]

	---@class class-system.create.options.interface.pretty
	---@field inherit any | any[]

end

__bundler__.__files__["tools.utils"] = function()
	---@diagnostic disable

	local __bundler__ = {
	    __files__ = {},
	    __binary_files__ = {},
	    __cache__ = {},
	    __temp_files__ = {},
	    __org_exit__ = os.exit
	}
	function __bundler__.__get_os__()
	    if package.config:sub(1, 1) == '\\' then
	        return "windows"
	    else
	        return "linux"
	    end
	end
	function __bundler__.__loadFile__(module)
	    if not __bundler__.__cache__[module] then
	        if __bundler__.__binary_files__[module] then
	        local tempDir = os.getenv("TEMP") or os.getenv("TMP")
	            if not tempDir then
	                tempDir = "/tmp"
	            end
	            local os_type = __bundler__.__get_os__()
	            local file_path = tempDir .. os.tmpname()
	            local file = io.open(file_path, "wb")
	            if not file then
	                error("unable to open file: " .. file_path)
	            end
	            local content
	            if os_type == "windows" then
	                content = __bundler__.__files__[module .. ".dll"]
	            else
	                content = __bundler__.__files__[module .. ".so"]
	            end
	            local content_len = content:len()
	            for i = 2, content_len, 2 do
	                local byte = tonumber(content:sub(i - 1, i), 16)
	                file:write(string.char(byte))
	            end
	            file:close()
	            __bundler__.__cache__[module] = { package.loadlib(file_path, "luaopen_" .. module)() }
	            table.insert(__bundler__.__temp_files__, file_path)
	        else
	            __bundler__.__cache__[module] = { __bundler__.__files__[module]() }
	        end
	    end
	    return table.unpack(__bundler__.__cache__[module])
	end
	function __bundler__.__cleanup__()
	    for _, file_path in ipairs(__bundler__.__temp_files__) do
	        os.remove(file_path)
	    end
	end
	---@diagnostic disable-next-line: duplicate-set-field
	function os.exit(...)
	    __bundler__.__cleanup__()
	    __bundler__.__org_exit__(...)
	end
	function __bundler__.__main__()
	    local loading_thread = coroutine.create(__bundler__.__loadFile__)
	    local success, items = (function(success, ...) return success, {...} end)
	        (coroutine.resume(loading_thread, "__main__"))
	    if not success then
	        print("error in bundle loading thread:\n"
	            .. debug.traceback(loading_thread, items[1]))
	    end
	    __bundler__.__cleanup__()
	    return table.unpack(items)
	end
	__bundler__.__files__["src.utils.number"] = function()
		---@class Freemaker.utils.number
		local _number = {}

		---@type table<integer, integer>
		local round_cache = {}

		---@param value number
		---@param decimal integer | nil
		---@return integer
		function _number.round(value, decimal)
		    decimal = decimal or 0
		    if decimal > 308 then
		        error("cannot round more decimals than 308")
		    end

		    local mult = round_cache[decimal]
		    if not mult then
		        mult = 10 ^ decimal
		        round_cache[decimal] = mult
		    end

		    return ((value * mult + 0.5) // 1) / mult
		end

		---@param value number
		---@param min number
		---@param max number
		---@return number
		function _number.clamp(value, min, max)
		    if value < min then
		        return min
		    end

		    if value > max then
		        return max
		    end

		    return value
		end

		return _number

	end

	__bundler__.__files__["src.utils.string.builder"] = function()
		local table_insert = table.insert
		local table_concat = table.concat

		---@class Freemaker.utils.string.builder
		---@field private m_cache string[]
		local _string_builder = {}

		function _string_builder.new()
		    local instance = setmetatable({
		        m_cache = {}
		    }, { __index = _string_builder })
		    return instance
		end

		function _string_builder:append(...)
		    for _, value in ipairs({...}) do
		        table_insert(self.m_cache, tostring(value))
		    end
		end

		function _string_builder:append_line(...)
		    self:append(...)
		    self:append("\n")
		end

		function _string_builder:build()
		    return table_concat(self.m_cache)
		end

		return _string_builder

	end

	__bundler__.__files__["src.utils.string.init"] = function()
		---@class Freemaker.utils.string
		---@field builder Freemaker.utils.string.builder
		local _string = {
		    builder = __bundler__.__loadFile__("src.utils.string.builder")
		}

		---@param str string
		---@param pattern string
		---@param plain boolean | nil
		---@return string | nil, integer
		local function find_next(str, pattern, plain)
		    local found = str:find(pattern, 0, plain or true)

		    if found == nil then
		        return nil, 0
		    end

		    return str:sub(0, found - 1), found - 1
		end

		---@param str string | nil
		---@param sep string | nil
		---@param plain boolean | nil
		---@return string[]
		function _string.split(str, sep, plain)
		    if str == nil then
		        return {}
		    end

		    local strLen = str:len()
		    local sepLen

		    if sep == nil then
		        sep = "%s"
		        sepLen = 2
		    else
		        sepLen = sep:len()
		    end

		    local tbl = {}
		    local i = 0
		    while true do
		        i = i + 1
		        local foundStr, foundPos = find_next(str, sep, plain)

		        if foundStr == nil then
		            tbl[i] = str
		            return tbl
		        end

		        tbl[i] = foundStr
		        str = str:sub(foundPos + sepLen + 1, strLen)
		    end
		end

		---@param str string | nil
		---@return boolean
		function _string.is_nil_or_empty(str)
		    if str == nil then
		        return true
		    end

		    if str == "" then
		        return true
		    end

		    return false
		end

		---@param str string
		---@param length integer
		---@param char string | nil
		function _string.left_pad(str, length, char)
		    local str_length = str:len()
		    return string.rep(char or " ", length - str_length) .. str
		end

		---@param str string
		---@param length integer
		---@param char string | nil
		function _string.right_pad(str, length, char)
		    local str_length = str:len()
		    return str .. string.rep(char or " ", length - str_length)
		end

		return _string

	end

	__bundler__.__files__["src.utils.table"] = function()
		---@class Freemaker.utils.table
		local _table = {}

		---@param t table
		---@param copy table
		---@param seen table<table, table>
		---@return table
		local function copy_table_to(t, copy, seen)
		    if seen[t] then
		        return seen[t]
		    end

		    seen[t] = copy

		    for key, value in next, t do
		        if type(value) == "table" then
		            copy[key] = copy_table_to(value, copy[key] or {}, seen)
		        else
		            copy[key] = value
		        end
		    end

		    local t_meta = getmetatable(t)
		    if t_meta then
		        local copy_meta = getmetatable(copy) or {}
		        copy_table_to(t_meta, copy_meta, seen)
		        setmetatable(copy, copy_meta)
		    end

		    return copy
		end

		---@generic T
		---@param t T
		---@return T table
		function _table.copy(t)
		    return copy_table_to(t, {}, {})
		end

		---@generic T
		---@param from T
		---@param to T
		function _table.copy_to(from, to)
		    copy_table_to(from, to, {})
		end

		---@param t table
		---@param ignoreProperties string[] | nil
		function _table.clear(t, ignoreProperties)
		    if not ignoreProperties then
		        for key, _ in next, t, nil do
		            t[key] = nil
		        end
		    else
		        for key, _ in next, t, nil do
		            if not _table.contains(ignoreProperties, key) then
		                t[key] = nil
		            end
		        end
		    end

		    setmetatable(t, nil)
		end

		---@param t table
		---@param value any
		---@return boolean
		function _table.contains(t, value)
		    for _, tValue in pairs(t) do
		        if value == tValue then
		            return true
		        end
		    end

		    return false
		end

		---@param t table
		---@param key any
		---@return boolean
		function _table.contains_key(t, key)
		    if t[key] ~= nil then
		        return true
		    end

		    return false
		end

		---@param t table
		---@return integer count
		function _table.count(t)
		    local count = 0

		    for _, _ in next, t, nil do
		        count = count + 1
		    end

		    return count
		end

		---@param t table
		---@return table
		function _table.invert(t)
		    local inverted = {}

		    for key, value in pairs(t) do
		        inverted[value] = key
		    end

		    return inverted
		end

		---@generic T
		---@generic R
		---@param t T[]
		---@param func fun(value: T) : R
		---@return R[]
		function _table.map(t, func)
		    ---@type any[]
		    local result = {}

		    for index, value in ipairs(t) do
		        result[index] = func(value)
		    end

		    return result
		end

		-- Only makes this table readonly
		-- **NOT** the child tables
		---@generic T
		---@param t T
		---@return T
		function _table.readonly(t)
		    return setmetatable({}, {
		        __newindex = function()
		            error("this table is readonly")
		        end,
		        __index = t
		    })
		end

		---@generic T
		---@generic R
		---@param t T
		---@param func fun(key: any, value: any) : R
		---@return R[]
		function _table.select(t, func)
		    local copy = _table.copy(t)

		    for key, value in pairs(copy) do
		        if not func(key, value) then
		            copy[key] = nil
		        end
		    end

		    return copy
		end

		---@generic T
		---@generic R
		---@param t T
		---@param func fun(key: any, value: any) : R
		---@return R[]
		function _table.select_implace(t, func)
		    for key, value in pairs(t) do
		        if not func(key, value) then
		            t[key] = nil
		        end
		    end

		    return t
		end

		return _table

	end

	__bundler__.__files__["src.utils.array"] = function()
		local table_insert = table.insert

		---@generic T
		---@param t T[]
		---@param value T
		local function insert_first_nil(t, value)
		    local i = 0
		    while true do
		        i = i + 1
		        if t[i] == nil then
		            t[i] = value
		            return
		        end
		    end
		end

		---@class Freemaker.utils.array
		local _array = {}

		---@generic T
		---@param t T[]
		---@param amount integer
		---@return T[]
		function _array.take_front(t, amount)
		    local length = #t
		    if amount > length then
		        amount = length
		    end

		    local copy = {}
		    for i = 1, amount, 1 do
		        table_insert(copy, t[i])
		    end
		    return copy
		end

		---@generic T
		---@param t T[]
		---@param amount integer
		---@return T[]
		function _array.take_back(t, amount)
		    local length = #t
		    local start = #t - amount + 1
		    if start < 1 then
		        start = 1
		    end

		    local copy = {}
		    for i = start, length, 1 do
		        table_insert(copy, t[i])
		    end
		    return copy
		end

		---@generic T
		---@param t T[]
		---@param amount integer
		---@return T[]
		function _array.drop_front_implace(t, amount)
		    for i, value in ipairs(t) do
		        if i <= amount then
		            t[i] = nil
		        else
		            insert_first_nil(t, value)
		            t[i] = nil
		        end
		    end
		    return t
		end

		---@generic T
		---@param t T[]
		---@param amount integer
		---@return T[]
		function _array.drop_back_implace(t, amount)
		    local length = #t
		    local start = length - amount + 1

		    for i = start, length, 1 do
		        t[i] = nil
		    end
		    return t
		end

		---@generic T
		---@generic R
		---@param t T[]
		---@param func fun(index: integer, value: T) : R
		---@return R[]
		function _array.select(t, func)
		    local copy = {}
		    for index, value in pairs(t) do
		        table_insert(copy, func(index, value))
		    end
		    return copy
		end

		---@generic T
		---@generic R
		---@param t T[]
		---@param func fun(index: integer, value: T) : R
		---@return R[]
		function _array.select_implace(t, func)
		    for index, value in pairs(t) do
		        local new_value = func(index, value)
		        t[index] = nil
		        if new_value then
		            insert_first_nil(t, new_value)
		        end
		    end
		    return t
		end

		--- removes all spaces between
		---@param t any[]
		function _array.clean(t)
		    for key, value in pairs(t) do
		        for i = key - 1, 1, -1 do
		            if key == 1 then
		                goto continue
		            end

		            if t[i] == nil and (t[i - 1] ~= nil or i == 1) then
		                t[i] = value
		                t[key] = nil
		                break
		            end

		            ::continue::
		        end
		    end
		end

		return _array

	end

	__bundler__.__files__["src.utils.value"] = function()
		local table = __bundler__.__loadFile__("src.utils.table")

		---@class Freemaker.utils.value
		local _value = {}

		---@generic T
		---@param x T
		---@return T
		function _value.copy(x)
		    local typeStr = type(x)
		    if typeStr == "table" then
		        return table.copy(x)
		    end

		    return x
		end

		---@generic T
		---@param value T | nil
		---@param default_value T
		---@return T
		function _value.default(value, default_value)
		    if value == nil then
		        return default_value
		    end

		    return value
		end

		return _value

	end

	__bundler__.__files__["src.utils.stopwatch"] = function()
		local _number = __bundler__.__loadFile__("src.utils.number")

		---@class Freemaker.utils.stopwatch
		---@field private running boolean
		---
		---@field start_time number
		---@field end_time number
		---@field private elapesd_milliseconds integer
		---
		---@field private laps integer[]
		---@field private laps_count integer
		local _stopwatch = {}

		---@return Freemaker.utils.stopwatch
		function _stopwatch.new()
		    return setmetatable({
		        running = false,

		        start_time = 0,
		        end_time = 0,
		        elapesd_milliseconds = 0,

		        laps = {},
		        laps_count = 0,
		    }, { __index = _stopwatch })
		end

		---@return Freemaker.utils.stopwatch
		function _stopwatch.start_new()
		    local instance = _stopwatch.new()
		    instance:start()
		    return instance
		end

		function _stopwatch:start()
		    if self.running then
		        return
		    end

		    self.start_time = os.clock()
		    self.running = true
		end

		function _stopwatch:stop()
		    if not self.running then
		        return
		    end

		    self.end_time = os.clock()
		    local elapesd_time = self.end_time - self.start_time
		    self.running = false

		    self.elapesd_milliseconds = _number.round(elapesd_time * 1000)
		end

		---@return integer
		function _stopwatch:get_elapesd_seconds()
		    return _number.round(self.elapesd_milliseconds / 1000)
		end

		---@return integer
		function _stopwatch:get_elapesd_milliseconds()
		    return self.elapesd_milliseconds
		end

		---@return integer elapesd_milliseconds
		function _stopwatch:lap()
		    if not self.running then
		        return 0
		    end

		    local lap_time = os.clock() * 1000
		    local previous_lap = self.laps[self.laps_count] or self.start_time

		    self.laps_count = self.laps_count + 1
		    self.laps[self.laps_count] = lap_time
		    local elapesd_time = lap_time - previous_lap

		    return _number.round(elapesd_time)
		end

		---@return integer elapesd_milliseconds
		function _stopwatch:avg_lap()
		    if not self.running then
		        return 0
		    end

		    self:lap()

		    local sum = 0
		    for _, lap_time in ipairs(self.laps) do
		        sum = sum + lap_time
		    end

			return sum / self.laps_count
		end

		return _stopwatch

	end

	__bundler__.__files__["__main__"] = function()
		---@class Freemaker.utils
		---@field number Freemaker.utils.number
		---@field string Freemaker.utils.string
		---@field table Freemaker.utils.table
		---@field array Freemaker.utils.array
		---@field value Freemaker.utils.value
		---
		---@field stopwatch Freemaker.utils.stopwatch
		local utils = {}

		utils.number = __bundler__.__loadFile__("src.utils.number")
		utils.string = __bundler__.__loadFile__("src.utils.string.init")
		utils.table = __bundler__.__loadFile__("src.utils.table")
		utils.array = __bundler__.__loadFile__("src.utils.array")
		utils.value = __bundler__.__loadFile__("src.utils.value")

		utils.stopwatch = __bundler__.__loadFile__("src.utils.stopwatch")

		return utils

	end

	---@type { [1]: Freemaker.utils }
	local main = { __bundler__.__main__() }
	return table.unpack(main)

end

__bundler__.__files__["src.class"] = function()
	---@class class-system
	local class = {}

	---@param obj any
	---@return class-system.type | nil
	function class.typeof(obj)
	    if not type(obj) == "table" then
	        return nil
	    end

	    ---@type class-system.metatable
	    local metatable = getmetatable(obj)
	    if not metatable then
	        return nil
	    end

	    return metatable.type
	end

	---@param obj any
	---@return string
	function class.nameof(obj)
	    local type_info = class.typeof(obj)
	    if not type_info then
	        return type(obj)
	    end

	    return type_info.name
	end

	---@param obj object
	---@return class-system.instance | nil
	function class.get_instance_data(obj)
	    if not class.is_class(obj) then
	        return
	    end

	    ---@type class-system.metatable
	    local metatable = getmetatable(obj)
	    return metatable.instance
	end

	---@param obj any
	---@return boolean isClass
	function class.is_class(obj)
	    if type(obj) ~= "table" then
	        return false
	    end

	    ---@type class-system.metatable
	    local metatable = getmetatable(obj)

	    if not metatable then
	        return false
	    end

	    if not metatable.type then
	        return false
	    end

	    if not metatable.type.name then
	        return false
	    end

	    return true
	end

	---@param obj any
	---@param className string
	---@return boolean hasBaseClass
	function class.has_base(obj, className)
	    if not class.is_class(obj) then
	        return false
	    end

	    ---@type class-system.metatable
	    local metatable = getmetatable(obj)

	    ---@param type_info class-system.type
	    local function hasBase(type_info)
	        local typeName = type_info.name
	        if typeName == className then
	            return true
	        end

	        if not type_info.base then
	            return false
	        end

	        return hasBase(type_info.base)
	    end

	    return hasBase(metatable.type)
	end

	---@param obj any
	---@param interfaceName string
	---@return boolean hasInterface
	function class.has_interface(obj, interfaceName)
	    if not class.is_class(obj) then
	        return false
	    end

	    ---@type class-system.metatable
	    local metatable = getmetatable(obj)

	    ---@param type_info class-system.type
	    local function hasInterface(type_info)
	        local typeName = type_info.name
	        if typeName == interfaceName then
	            return true
	        end

	        for _, value in pairs(type_info.interfaces) do
	            if hasInterface(value) then
	                return true
	            end
	        end

	        return false
	    end

	    return hasInterface(metatable.type)
	end

	return class

end

__bundler__.__files__["src.object"] = function()
	local utils = __bundler__.__loadFile__("tools.utils")
	local config = __bundler__.__loadFile__("src.config")
	local class = __bundler__.__loadFile__("src.class")

	---@class object
	local object = {}

	---@protected
	---@return string typeName
	function object:__tostring()
	    return class.typeof(self).name
	end

	---@protected
	---@return string
	function object.__concat(left, right)
	    return tostring(left) .. tostring(right)
	end

	---@class class-system.object.modify
	---@field custom_indexing boolean | nil

	---@protected
	---@param func fun(modify: class-system.object.modify)
	function object:raw__modify_behavior(func)
	    ---@type class-system.metatable
	    local metatable = getmetatable(self)

	    local modify = {
	        custom_indexing = metatable.instance.custom_indexing
	    }

	    func(modify)

	    metatable.instance.custom_indexing = modify.custom_indexing
	end

	----------------------------------------
	-- Type Info
	----------------------------------------

	---@type class-system.type
	local object_type_info = {
	    name = "object",
	    base = nil,
	    interfaces = {},

	    static = {},
	    meta_methods = {},
	    members = {},

	    has_pre_constructor = false,
	    has_constructor = false,
	    has_deconstructor = false,
	    has_close = false,
	    has_index = false,
	    has_new_index = false,

	    options = {
	        is_abstract = true,
	    },

	    instances = setmetatable({}, { __mode = 'k' }),

	    -- no blueprint since cannot be constructed
	    blueprint = nil
	}

	for key, value in pairs(object) do
	    if config.all_meta_methods[key] then
	        object_type_info.meta_methods[key] = value
	    else
	        if type(key) == 'string' then
	            local splittedKey = utils.string.split(key, '__')
	            if utils.table.contains(splittedKey, 'Static') then
	                object_type_info.static[key] = value
	            else
	                object_type_info.members[key] = value
	            end
	        else
	            object_type_info.members[key] = value
	        end
	    end
	end

	setmetatable(
	        object_type_info,
	        {
	            __tostring = function(self)
	                return self.Name
	            end
	        }
	    )

	return object_type_info

end

__bundler__.__files__["src.type"] = function()
	---@class class-system.type_handler
	local type_handler = {}

	---@param base class-system.type | nil
	---@param interfaces table<class-system.type>
	---@param options class-system.create.options
	function type_handler.create(base, interfaces, options)
	    local type_info = {
	        name = options.name,
	        base = base,
	        interfaces = interfaces,

	        options = options,

	        meta_methods = {},
	        members = {},
	        static = {},

	        instances = setmetatable({}, { __mode = "k" }),
	    }

	    options.name = nil
	    options.inherit = nil
	    ---@cast type_info class-system.type

	    setmetatable(
	        type_info,
	        {
	            __tostring = function(self)
	                return self.Name
	            end
	        }
	    )

	    return type_info
	end

	return type_handler

end

__bundler__.__files__["src.instance"] = function()
	local utils = __bundler__.__loadFile__("tools.utils")

	---@class class-system.instance_handler
	local instance_handler = {}

	---@param instance class-system.instance
	function instance_handler.initialize(instance)
	    instance.custom_indexing = true
	    instance.is_constructed = false
	end

	---@param type_info class-system.type
	---@param instance object
	function instance_handler.add(type_info, instance)
	    type_info.instances[instance] = true

	    if type_info.base then
	        instance_handler.add(type_info.base, instance)
	    end

	    for _, parent in pairs(type_info.interfaces) do
	        instance_handler.add(parent, instance)
	    end
	end

	---@param type_info class-system.type
	---@param instance object
	function instance_handler.remove(type_info, instance)
	    type_info.instances[instance] = nil

	    if type_info.base then
	        instance_handler.remove(type_info.base, instance)
	    end

	    for _, parent in pairs(type_info.interfaces) do
	        instance_handler.remove(parent, instance)
	    end
	end

	---@param type_info class-system.type
	---@param name string
	---@param func function
	function instance_handler.update_meta_method(type_info, name, func)
	    type_info.meta_methods[name] = func

	    for instance in pairs(type_info.instances) do
	        local instanceMetatable = getmetatable(instance)

	        if not utils.table.contains_key(instanceMetatable, name) then
	            instanceMetatable[name] = func
	        end
	    end
	end

	---@param type_info class-system.type
	---@param key any
	---@param value any
	function instance_handler.update_member(type_info, key, value)
	    type_info.members[key] = value

	    for instance in pairs(type_info.instances) do
	        if not utils.table.contains_key(instance, key) then
	            rawset(instance, key, value)
	        end
	    end
	end

	return instance_handler

end

__bundler__.__files__["src.members"] = function()
	local utils = __bundler__.__loadFile__("tools.utils")

	local config = __bundler__.__loadFile__("src.config")

	local instance_handler = __bundler__.__loadFile__("src.instance")

	---@class class-system.members_handler
	local members_handler = {}

	---@param type_info class-system.type
	function members_handler.update_state(type_info)
	    local metaMethods = type_info.meta_methods

	    type_info.has_constructor = metaMethods.__init ~= nil
	    type_info.has_deconstructor = metaMethods.__gc ~= nil
	    type_info.has_close = metaMethods.__close ~= nil
	    type_info.has_index = metaMethods.__index ~= nil
	    type_info.has_new_index = metaMethods.__newindex ~= nil
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

end

__bundler__.__files__["src.metatable"] = function()
	local utils = __bundler__.__loadFile__("tools.utils")

	local config = __bundler__.__loadFile__("src.config")

	local members_handler = __bundler__.__loadFile__("src.members")

	---@class class-system.metatable_handler
	local metatable_handler = {}

	---@param type_info class-system.type
	---@return class-system.blueprint-metatable metatable
	function metatable_handler.create_template_metatable(type_info)
	    ---@type class-system.blueprint-metatable
	    local metatable = { type = type_info }

	    metatable.__index = members_handler.template_index(type_info)
	    metatable.__newindex = members_handler.template_new_index(type_info)

	    for key in pairs(config.block_meta_methods_on_blueprint) do
	        local function blockMetaMethod()
	            error("cannot use meta method: " .. key .. " on a template from a class")
	        end
	        ---@diagnostic disable-next-line: assign-type-mismatch
	        metatable[key] = blockMetaMethod
	    end

	    metatable.__tostring = function()
	        return type_info.name .. ".__blueprint__"
	    end

	    return metatable
	end

	---@param type_info class-system.type
	---@param instance class-system.instance
	---@param metatable class-system.metatable
	function metatable_handler.create(type_info, instance, metatable)
	    metatable.type = type_info

	    metatable.__index = members_handler.instance_index(instance, type_info)
	    metatable.__newindex = members_handler.instance_new_index(instance, type_info)

	    for key, _ in pairs(config.block_meta_methods_on_instance) do
	        if not utils.table.contains_key(type_info.meta_methods, key) then
	            local function blockMetaMethod()
	                error("cannot use meta method: " .. key .. " on class: " .. type_info.name)
	            end
	            metatable[key] = blockMetaMethod
	        end
	    end
	end

	return metatable_handler

end

__bundler__.__files__["src.construction"] = function()
	local utils = __bundler__.__loadFile__("tools.utils")

	local config = __bundler__.__loadFile__("src.config")

	local instance_handler = __bundler__.__loadFile__("src.instance")
	local metatable_handler = __bundler__.__loadFile__("src.metatable")

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

	    if type_info.base then
	        if type_info.base.has_constructor then
	            function super(...)
	                constructMembers()
	                construction_handler.construct(type_info.base, obj, instance, metatable, ...)
	                return obj
	            end
	        else
	            constructMembers()
	            construction_handler.construct(type_info.base, obj, instance, metatable)
	        end
	    else
	        constructMembers()
	    end

	    if type_info.has_constructor then
	        if super then
	            type_info.meta_methods.__init(obj, super, ...)
	        else
	            type_info.meta_methods.__init(obj, ...)
	        end
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

end

__bundler__.__files__["__main__"] = function()
	-- required at top to be at the top of the bundled file
	local configs = __bundler__.__loadFile__("src.config")

	-- to package meta in the bundled file
	__bundler__.__loadFile__("src.meta")

	local utils = __bundler__.__loadFile__("tools.utils")

	local class = __bundler__.__loadFile__("src.class")
	local object_type = __bundler__.__loadFile__("src.object")
	local type_handler = __bundler__.__loadFile__("src.type")
	local members_handler = __bundler__.__loadFile__("src.members")
	local construction_handler = __bundler__.__loadFile__("src.construction")

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
	    local createOptions = {}
	    createOptions.name = name
	    createOptions.is_abstract = options.is_abstract
	    createOptions.inherit = options.inherit

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
	    local createOptions = {}
	    createOptions.name = name
	    createOptions.is_interface = true
	    createOptions.inherit = options.inherit

	    return class_system.create(table, createOptions)
	end

	_G.typeof = class_system.typeof
	_G.nameof = class_system.nameof

	return class_system

end

---@type { [1]: class-system }
local main = { __bundler__.__main__() }
return table.unpack(main)
