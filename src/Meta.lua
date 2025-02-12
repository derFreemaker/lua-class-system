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
---@field name string
---
---@field inherit object[] | object | nil

---@class class-system.create.options.class.pretty
---@field is_abstract boolean | nil
---
---@field inherit any | any[]

---@class class-system.create.options.interface.pretty
---@field inherit any | any[]
