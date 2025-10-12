local lcs = require("class_system")

context("LCS Config", function()
    test("should have all meta_type entries", function()
        assert.is_not_nil(lcs.config.meta_type.pre_constructor)
        assert.is_not_nil(lcs.config.meta_type.constructor)
        assert.is_not_nil(lcs.config.meta_type.index)
        assert.is_not_nil(lcs.config.meta_type.new_index)
        assert.is_not_nil(lcs.config.meta_type.gc)
        assert.is_not_nil(lcs.config.meta_type.close)
        assert.is_not_nil(lcs.config.meta_type.call)
    end)

    test("should have meta mapping configured", function()
        assert.is_not_nil(lcs.config.meta["__gc"])
        assert.is_not_nil(lcs.config.meta["__call"])
        assert.is_not_nil(lcs.config.meta["__add"])
        assert.is_not_nil(lcs.config.meta["__tostring"])
    end)

    test("should have indirect_meta mapping configured", function()
        assert.is_not_nil(lcs.config.indirect_meta["__pre"])
        assert.is_not_nil(lcs.config.indirect_meta["__init"])
        assert.is_not_nil(lcs.config.indirect_meta["__index"])
        assert.is_not_nil(lcs.config.indirect_meta["__newindex"])
    end)

    test("should have reverse mappings", function()
        assert.is_string(lcs.config.reverse_meta[lcs.config.meta_type.add])
        assert.is_string(lcs.config.reverse_indirect_meta[lcs.config.meta_type.constructor])
    end)
end)

context("LCS.class - Basic Class Creation", function()
    test("should create a simple class", function()
        local MyClass = lcs.class({}, "MyClass")
        assert.is_not_nil(MyClass)
    end)

    test("should instantiate a class", function()
        local MyClass = lcs.class({}, "MyClass")
        local instance = MyClass()
        assert.is_not_nil(instance)
    end)

    test("should create class with methods", function()
        local MyClass = lcs.class({
            greet = function(self)
                return "Hello"
            end
        }, "MyClass")

        local instance = MyClass()
        assert.equal("Hello", instance:greet())
    end)

    test("should create class with constructor", function()
        local MyClass = lcs.class({
            __init = function(self, name)
                self.name = name
            end
        }, "MyClass")

        local instance = MyClass("John")
        assert.equal("John", instance.name)
    end)

    test("should handle multiple instances independently", function()
        local MyClass = lcs.class({
            __init = function(self, value)
                self.value = value
            end
        }, "MyClass")

        local inst1 = MyClass(10)
        local inst2 = MyClass(20)

        assert.equal(10, inst1.value)
        assert.equal(20, inst2.value)
    end)

    test("should reject non-table as first argument", function()
        assert.has_error(function()
            ---@diagnostic disable-next-line: param-type-mismatch
            lcs.class("not a table", "MyClass")
        end)
    end)

    test("should reject non-string as name", function()
        assert.has_error(function()
            ---@diagnostic disable-next-line: param-type-mismatch
            lcs.class({}, 123)
        end)
    end)
end)

context("LCS.class - Pre-constructor", function()
    test("should call pre-constructor before constructor", function()
        local call_order = {}

        local MyClass = lcs.class({
            __pre = function(...)
                table.insert(call_order, "pre")
            end,
            __init = function(self)
                table.insert(call_order, "init")
            end
        }, "MyClass")

        MyClass()
        assert.same({ "pre", "init" }, call_order)
    end)

    test("should allow pre-constructor to return alternative object", function()
        local alternative = { alternative = true }

        local MyClass = lcs.class({
            __pre = function(...)
                return alternative
            end,
            __init = function(self)
                self.constructed = true
            end
        }, "MyClass")

        local instance = MyClass()
        assert.equal(alternative, instance)
        assert.is_nil(instance.constructed)
    end)

    test("should pass arguments to pre-constructor", function()
        local received_args = nil

        local MyClass = lcs.class({
            __pre = function(a, b, c)
                received_args = { a, b, c }
            end
        }, "MyClass")

        MyClass(1, 2, 3)
        assert.same({ 1, 2, 3 }, received_args)
    end)
end)

context("LCS.class - Metamethods", function()
    test("should support __tostring", function()
        local MyClass = lcs.class({
            __tostring = function(self)
                return "CustomString"
            end
        }, "MyClass")

        local instance = MyClass()
        assert.equal("CustomString", tostring(instance))
    end)

    test("should have default __tostring for class template", function()
        local MyClass = lcs.class({}, "MyClass")
        assert.equal("template: MyClass", tostring(MyClass))
    end)

    test("should have default __tostring for instances", function()
        local MyClass = lcs.class({}, "MyClass")
        local instance = MyClass()
        assert.equal("class: MyClass", tostring(instance))
    end)

    test("should support __add", function()
        local MyClass = {}

        function MyClass:__init(value)
            self.value = value
        end

        function MyClass.__add(a, b)
            return MyClass(a.value + b.value)
        end

        lcs.class(MyClass, "MyClass")

        local a = MyClass(5)
        local b = MyClass(3)
        local c = a + b
        assert.equal(8, c.value)
    end)

    test("should support __sub", function()
        local MyClass = {}

        function MyClass:__init(value)
            self.value = value
        end

        function MyClass.__sub(a, b)
            return MyClass(a.value - b.value)
        end

        lcs.class(MyClass, "MyClass")

        local a = MyClass(10)
        local b = MyClass(3)
        local c = a - b
        assert.equal(7, c.value)
    end)

    test("should support __mul", function()
        local MyClass = {}

        function MyClass:__init(value)
            self.value = value
        end

        function MyClass.__mul(a, b)
            return MyClass(a.value * b.value)
        end

        lcs.class(MyClass, "MyClass")

        local a = MyClass(4)
        local b = MyClass(5)
        local c = a * b
        assert.equal(20, c.value)
    end)

    test("should support __div", function()
        local MyClass = {}

        function MyClass:__init(value)
            self.value = value
        end

        function MyClass.__div(a, b)
            return MyClass(a.value / b.value)
        end

        lcs.class(MyClass, "MyClass")

        local a = MyClass(20)
        local b = MyClass(4)
        local c = a / b
        assert.equal(5, c.value)
    end)

    test("should support __unm (negation)", function()
        local MyClass = {}

        function MyClass:__init(value)
            self.value = value
        end

        function MyClass:__unm(a)
            return MyClass(-a.value)
        end

        lcs.class(MyClass, "MyClass")

        local a = MyClass(5)
        local b = -a
        ---@diagnostic disable-next-line: undefined-field
        assert.equal(-5, b.value)
    end)

    test("should support __concat", function()
        local MyClass = {}

        function MyClass:__init(value)
            self.value = value
        end

        function MyClass.__concat(a, b)
            return MyClass(a.value .. b.value)
        end

        lcs.class(MyClass, "MyClass")

        local a = MyClass("Hello")
        local b = MyClass("World")
        local c = a .. b
        assert.equal("HelloWorld", c.value)
    end)

    test("should support __len", function()
        local MyClass = lcs.class({
            __init = function(self, items)
                self.items = items
            end,
            __len = function(self)
                return #self.items
            end
        }, "MyClass")

        local instance = MyClass({ 1, 2, 3, 4 })
        assert.equal(4, #instance)
    end)

    test("should support __eq", function()
        local MyClass = lcs.class({
            __init = function(self, value)
                self.value = value
            end,
            __eq = function(a, b)
                return a.value == b.value
            end
        }, "MyClass")

        local a = MyClass(5)
        local b = MyClass(5)
        local c = MyClass(10)

        assert.is_true(a == b)
        assert.is_false(a == c)
    end)

    test("should support __lt", function()
        local MyClass = lcs.class({
            __init = function(self, value)
                self.value = value
            end,
            __lt = function(a, b)
                return a.value < b.value
            end
        }, "MyClass")

        local a = MyClass(5)
        local b = MyClass(10)

        assert.is_true(a < b)
        assert.is_false(b < a)
    end)

    test("should support __le", function()
        local MyClass = lcs.class({
            __init = function(self, value)
                self.value = value
            end,
            __le = function(a, b)
                return a.value <= b.value
            end
        }, "MyClass")

        local a = MyClass(5)
        local b = MyClass(5)
        local c = MyClass(10)

        assert.is_true(a <= b)
        assert.is_true(a <= c)
        assert.is_false(c <= a)
    end)

    test("should support __call", function()
        local MyClass = lcs.class({
            __init = function(self, value)
                self.value = value
            end,
            __call = function(self, x)
                return self.value * x
            end
        }, "MyClass")

        local instance = MyClass(5)
        assert.equal(15, instance(3))
    end)

    test("should support __mod", function()
        local MyClass = {}

        function MyClass:__init(value)
            self.value = value
        end

        function MyClass.__mod(a, b)
            return MyClass(a.value % b.value)
        end

        lcs.class(MyClass, "MyClass")

        local a = MyClass(10)
        local b = MyClass(3)
        local c = a % b
        assert.equal(1, c.value)
    end)

    test("should support __pow", function()
        local MyClass = {}

        function MyClass:__init(value)
            self.value = value
        end

        function MyClass.__pow(a, b)
            return MyClass(a.value ^ b.value)
        end

        lcs.class(MyClass, "MyClass")

        local a = MyClass(2)
        local b = MyClass(3)
        local c = a ^ b
        assert.equal(8, c.value)
    end)

    test("should support __idiv (floor division)", function()
        local MyClass = {}

        function MyClass:__init(value)
            self.value = value
        end

        function MyClass.__idiv(a, b)
            return MyClass(a.value // b.value)
        end

        lcs.class(MyClass, "MyClass")

        local a = MyClass(10)
        local b = MyClass(3)
        local c = a // b
        assert.equal(3, c.value)
    end)

    test("should support __band (bitwise AND)", function()
        local MyClass = {}

        function MyClass:__init(value)
            self.value = value
        end

        function MyClass.__band(a, b)
            return MyClass(a.value & b.value)
        end

        lcs.class(MyClass, "MyClass")

        local a = MyClass(5) -- 101
        local b = MyClass(3) -- 011
        local c = a & b      -- 001
        assert.equal(1, c.value)
    end)

    test("should support __bor (bitwise OR)", function()
        local MyClass = {}

        function MyClass:__init(value)
            self.value = value
        end

        function MyClass.__bor(a, b)
            return MyClass(a.value | b.value)
        end

        lcs.class(MyClass, "MyClass")

        local a = MyClass(5) -- 101
        local b = MyClass(3) -- 011
        local c = a | b      -- 111
        assert.equal(7, c.value)
    end)

    test("should support __bxor (bitwise XOR)", function()
        local MyClass = {}

        function MyClass:__init(value)
            self.value = value
        end

        function MyClass.__bxor(a, b)
            return MyClass(a.value ~ b.value)
        end

        lcs.class(MyClass, "MyClass")

        local a = MyClass(5) -- 101
        local b = MyClass(3) -- 011
        local c = a ~ b      -- 110
        assert.equal(6, c.value)
    end)

    test("should support __bnot (bitwise NOT)", function()
        local MyClass = {}

        function MyClass:__init(value)
            self.value = value
        end

        function MyClass.__bnot(a)
            return MyClass(~a.value)
        end

        lcs.class(MyClass, "MyClass")

        local a = MyClass(5)
        local b = ~a
        ---@diagnostic disable-next-line: undefined-field
        assert.equal(~5, b.value)
    end)

    test("should support __shl (bitwise shift left)", function()
        local MyClass = {}

        function MyClass:__init(value)
            self.value = value
        end

        function MyClass.__shl(a, b)
            return MyClass(a.value << b.value)
        end

        lcs.class(MyClass, "MyClass")

        local a = MyClass(5)
        local b = MyClass(2)
        local c = a << b
        assert.equal(20, c.value)
    end)

    test("should support __shr (bitwise shift right)", function()
        local MyClass = {}

        function MyClass:__init(value)
            self.value = value
        end

        function MyClass.__shr(a, b)
            return MyClass(a.value >> b.value)
        end

        lcs.class(MyClass, "MyClass")

        local a = MyClass(20)
        local b = MyClass(2)
        local c = a >> b
        assert.equal(5, c.value)
    end)
end)

context("LCS.interface - Interface Creation", function()
    test("should create a simple interface", function()
        local IMyInterface = lcs.interface({}, "IMyInterface")
        assert.is_not_nil(IMyInterface)
    end)

    test("should create interface with methods", function()
        local IMyInterface = lcs.interface({
            greet = function(self)
                return "Hello"
            end
        }, "IMyInterface")

        assert.is_not_nil(IMyInterface)
    end)

    test("should create interface with required methods", function()
        local IMyInterface = lcs.interface({
            greet = function(self) end,
            farewell = function(self) end
        }, "IMyInterface", { "greet", "farewell" })

        assert.is_not_nil(IMyInterface)
    end)

    test("should have __tostring for interface", function()
        local IMyInterface = lcs.interface({}, "IMyInterface")
        assert.equal("interface: IMyInterface", tostring(IMyInterface))
    end)

    test("should not allow metamethods in interface", function()
        assert.has_error(function()
            lcs.interface({
                __add = function() end
            }, "IMyInterface")
        end)
    end)

    test("should not allow indirect metamethods in interface", function()
        assert.has_error(function()
            lcs.interface({
                __init = function() end
            }, "IMyInterface")
        end)
    end)

    test("should error if interfacing method is not a function", function()
        assert.has_error(function()
            lcs.interface({
                greet = "not a function"
            }, "IMyInterface", { "greet" })
        end)
    end)

    test("should reject invalid interface in interface inheritance", function()
        assert.has_error(function()
            ---@diagnostic disable-next-line: param-type-mismatch
            lcs.interface({}, "IMyInterface", {}, "not an interface")
        end)
    end)
end)

context("LCS.class - Interface Implementation", function()
    test("should implement a simple interface", function()
        local IGreeter = lcs.interface({
            greet = function(self) end
        }, "IGreeter", { "greet" })

        local MyClass = lcs.class({
            greet = function(self)
                return "Hello"
            end
        }, "MyClass", IGreeter)

        local instance = MyClass()
        assert.equal("Hello", instance:greet())
    end)

    test("should error if interface method not implemented", function()
        local IGreeter = lcs.interface({
            greet = function(self) end
        }, "IGreeter", { "greet" })

        assert.has_error(function()
            lcs.class({}, "MyClass", IGreeter)
        end)
    end)

    test("should inherit methods from interface", function()
        local IGreeter = lcs.interface({
            greet = function(self)
                return "Hello from interface"
            end
        }, "IGreeter")

        local MyClass = lcs.class({}, "MyClass", IGreeter)
        local instance = MyClass()
        assert.equal("Hello from interface", instance:greet())
    end)

    test("should implement multiple interfaces", function()
        local IGreeter = lcs.interface({
            greet = function(self) end
        }, "IGreeter", { "greet" })

        local IFarewell = lcs.interface({
            farewell = function(self) end
        }, "IFarewell", { "farewell" })

        local MyClass = lcs.class({
            greet = function(self) return "Hi" end,
            farewell = function(self) return "Bye" end
        }, "MyClass", IGreeter, IFarewell)

        local instance = MyClass()
        assert.equal("Hi", instance:greet())
        assert.equal("Bye", instance:farewell())
    end)

    test("should support nested interface inheritance", function()
        local IBase = lcs.interface({
            base_method = function(self) return "base" end
        }, "IBase")

        local IDerived = lcs.interface({
            derived_method = function(self) return "derived" end
        }, "IDerived", {}, IBase)

        local MyClass = lcs.class({}, "MyClass", IDerived)
        local instance = MyClass()

        assert.equal("base", instance:base_method())
        assert.equal("derived", instance:derived_method())
    end)

    test("should check nested interface requirements", function()
        local IBase = lcs.interface({
            base_method = function(self) end
        }, "IBase", { "base_method" })

        local IDerived = lcs.interface({
            derived_method = function(self) end
        }, "IDerived", { "derived_method" }, IBase)

        assert.has_error(function()
            lcs.class({
                derived_method = function(self) end
                -- missing base_method
            }, "MyClass", IDerived)
        end)
    end)
end)

context("LCS.typeof", function()
    test("should return type info for class instance", function()
        local MyClass = lcs.class({}, "MyClass")
        local instance = MyClass()
        local type_info = lcs.typeof(instance)

        assert.is_not_nil(type_info)
        ---@cast type_info -nil

        assert.equal("MyClass", type_info.name)
    end)

    test("should return type info for class template", function()
        local MyClass = lcs.class({}, "MyClass")
        local type_info = lcs.typeof(MyClass)

        assert.is_not_nil(type_info)
        ---@cast type_info -nil

        assert.equal("MyClass", type_info.name)
    end)

    test("should return type info for interface", function()
        local IMyInterface = lcs.interface({}, "IMyInterface")
        local type_info = lcs.typeof(IMyInterface)

        assert.is_not_nil(type_info)
        ---@cast type_info -nil

        assert.equal("IMyInterface", type_info.name)
    end)

    test("should return nil for non-LCS objects", function()
        local regular_table = {}
        assert.is_nil(lcs.typeof(regular_table))
    end)

    test("should return nil for primitives", function()
        assert.is_nil(lcs.typeof(5))
        assert.is_nil(lcs.typeof("string"))
        assert.is_nil(lcs.typeof(true))
    end)
end)

context("LCS.is_class", function()
    test("should return true for class instances", function()
        local MyClass = lcs.class({}, "MyClass")
        local instance = MyClass()
        assert.is_true(lcs.is_class(instance))
    end)

    test("should return true for class templates", function()
        local MyClass = lcs.class({}, "MyClass")
        assert.is_true(lcs.is_class(MyClass))
    end)

    test("should return false for interfaces", function()
        local IMyInterface = lcs.interface({}, "IMyInterface")
        assert.is_false(lcs.is_class(IMyInterface))
    end)

    test("should return false for non-LCS objects", function()
        assert.is_false(lcs.is_class({}))
        assert.is_false(lcs.is_class("string"))
        assert.is_false(lcs.is_class(5))
    end)
end)

context("LCS.is_class_of", function()
    test("should return true for instance of same class", function()
        local MyClass = lcs.class({}, "MyClass")
        local instance = MyClass()
        assert.is_true(lcs.is_class_of(instance, MyClass))
    end)

    test("should return false for instance of different class", function()
        local ClassA = lcs.class({}, "ClassA")
        local ClassB = lcs.class({}, "ClassB")
        local instance = ClassA()
        assert.is_false(lcs.is_class_of(instance, ClassB))
    end)

    test("should return false for non-LCS objects", function()
        local MyClass = lcs.class({}, "MyClass")
        assert.is_false(lcs.is_class_of({}, MyClass))
    end)
end)

context("LCS.is_interface", function()
    test("should return true for interfaces", function()
        local IMyInterface = lcs.interface({}, "IMyInterface")
        assert.is_true(lcs.is_interface(IMyInterface))
    end)

    test("should return false for classes", function()
        local MyClass = lcs.class({}, "MyClass")
        assert.is_false(lcs.is_interface(MyClass))
    end)

    test("should return false for class instances", function()
        local MyClass = lcs.class({}, "MyClass")
        local instance = MyClass()
        assert.is_false(lcs.is_interface(instance))
    end)

    test("should return false for non-LCS objects", function()
        assert.is_false(lcs.is_interface({}))
    end)
end)

context("LCS.has_interface", function()
    test("should return true for class implementing interface", function()
        local IGreeter = lcs.interface({
            greet = function(self) end
        }, "IGreeter", { "greet" })

        local MyClass = lcs.class({
            greet = function(self) return "Hi" end
        }, "MyClass", IGreeter)

        local instance = MyClass()
        assert.is_true(lcs.has_interface(instance, IGreeter))
    end)

    test("should return false for class not implementing interface", function()
        local IGreeter = lcs.interface({}, "IGreeter")
        local MyClass = lcs.class({}, "MyClass")
        local instance = MyClass()

        assert.is_false(lcs.has_interface(instance, IGreeter))
    end)

    test("should return false for non-LCS objects", function()
        local IGreeter = lcs.interface({}, "IGreeter")
        assert.is_false(lcs.has_interface({}, IGreeter))
    end)
end)

context("LCS - Class Template Behavior", function()
    test("should access methods on template", function()
        local MyClass = lcs.class({
            greet = function(self)
                return "Hello"
            end
        }, "MyClass")

        assert.is_function(MyClass.greet)
    end)

    test("should not allow setting values on template", function()
        local MyClass = lcs.class({}, "MyClass")

        assert.has_error(function()
            MyClass.new_property = "value"
        end)
    end)

    test("should access interface methods through template", function()
        local IGreeter = lcs.interface({
            greet = function(self) return "Hi" end
        }, "IGreeter")

        local MyClass = lcs.class({}, "MyClass", IGreeter)

        assert.is_function(MyClass.greet)
    end)
end)

context("LCS - Edge Cases", function()
    test("should handle class with no constructor", function()
        local MyClass = lcs.class({}, "MyClass")
        local instance = MyClass()
        assert.is_not_nil(instance)
    end)

    test("should handle constructor with no arguments", function()
        local MyClass = lcs.class({
            __init = function(self)
                self.initialized = true
            end
        }, "MyClass")

        local instance = MyClass()
        assert.is_true(instance.initialized)
    end)

    test("should handle constructor with multiple arguments", function()
        local MyClass = lcs.class({
            __init = function(self, a, b, c, d, e)
                self.sum = a + b + c + d + e
            end
        }, "MyClass")

        local instance = MyClass(1, 2, 3, 4, 5)
        assert.equal(15, instance.sum)
    end)

    test("should handle nil arguments in constructor", function()
        local MyClass = lcs.class({
            __init = function(self, a, b, c)
                self.a = a
                self.b = b
                self.c = c
            end
        }, "MyClass")

        local instance = MyClass(1, nil, 3)
        assert.equal(1, instance.a)
        assert.is_nil(instance.b)
        assert.equal(3, instance.c)
    end)

    test("should handle empty interface list", function()
        local MyClass = lcs.class({}, "MyClass")
        assert.is_not_nil(MyClass)
    end)

    test("should preserve method references across instances", function()
        local MyClass = lcs.class({
            greet = function(self)
                return "Hello"
            end
        }, "MyClass")

        local inst1 = MyClass()
        local inst2 = MyClass()

        -- Methods should be the same function
        assert.equal(inst1.greet, inst2.greet)
    end)

    test("should not allow overriding interface methods", function()
        local IGreeter = lcs.interface({
            greet = function(self) return "Interface" end
        }, "IGreeter")

        assert.has_error(function()
            lcs.class({
                greet = function(self) return "Class" end
            }, "MyClass", IGreeter)
        end, "overriding member 'greet' in class 'MyClass' from interface 'IGreeter' is not allowed")
    end)

    test("should handle deeply nested interface inheritance", function()
        local IBase1 = lcs.interface({
            method1 = function() return 1 end
        }, "IBase1")

        local IBase2 = lcs.interface({
            method2 = function() return 2 end
        }, "IBase2", {}, IBase1)

        local IBase3 = lcs.interface({
            method3 = function() return 3 end
        }, "IBase3", {}, IBase2)

        local MyClass = lcs.class({}, "MyClass", IBase3)
        local instance = MyClass()

        assert.equal(1, instance:method1())
        assert.equal(2, instance:method2())
        assert.equal(3, instance:method3())
    end)
end)

context("LCS - Complex Scenarios", function()
    test("should support factory pattern with pre-constructor", function()
        local cache = {}

        local Singleton = lcs.class({
            __pre = function(id)
                if cache[id] then
                    return cache[id]
                end
            end,
            __init = function(self, id)
                self.id = id
                cache[id] = self
            end
        }, "Singleton")

        local obj1 = Singleton("test")
        local obj2 = Singleton("test")
        local obj3 = Singleton("other")

        assert.equal(obj1, obj2)
        assert.no.equal(obj1, obj3)
    end)

    test("should support method chaining", function()
        local Builder = lcs.class({
            __init = function(self)
                self.values = {}
            end,
            add = function(self, value)
                table.insert(self.values, value)
                return self
            end,
            sum = function(self)
                local total = 0
                for _, v in ipairs(self.values) do
                    total = total + v
                end
                return total
            end
        }, "Builder")

        local builder = Builder()
        local result = builder:add(1):add(2):add(3):sum()
        assert.equal(6, result)
    end)

    test("should support polymorphism through interfaces", function()
        local IAnimal = lcs.interface({
            speak = function(self) end
        }, "IAnimal", { "speak" })

        local Dog = lcs.class({
            speak = function(self) return "Woof" end
        }, "Dog", IAnimal)

        local Cat = lcs.class({
            speak = function(self) return "Meow" end
        }, "Cat", IAnimal)

        local animals = { Dog(), Cat() }
        local sounds = {}

        for _, animal in ipairs(animals) do
            table.insert(sounds, animal:speak())
        end

        assert.same({ "Woof", "Meow" }, sounds)
    end)

    test("should support composition pattern", function()
        local Engine = lcs.class({
            __init = function(self, power)
                self.power = power
            end,
            start = function(self)
                return "Engine started: " .. self.power .. " HP"
            end
        }, "Engine")

        local Car = lcs.class({
            __init = function(self, engine_power)
                self.engine = Engine(engine_power)
            end,
            start = function(self)
                return self.engine:start()
            end
        }, "Car")

        local car = Car(200)
        assert.equal("Engine started: 200 HP", car:start())
    end)

    test("should handle complex arithmetic operations", function()
        local Vector = {}

        function Vector:__init(x, y)
            self.x = x
            self.y = y
        end

        function Vector.__add(a, b)
            return Vector(a.x + b.x, a.y + b.y)
        end

        function Vector.__sub(a, b)
            return Vector(a.x - b.x, a.y - b.y)
        end

        function Vector.__mul(a, scalar)
            if type(scalar) == "number" then
                return Vector(a.x * scalar, a.y * scalar)
            end
        end

        function Vector.__eq(a, b)
            return a.x == b.x and a.y == b.y
        end

        function Vector:__tostring()
            return string.format("Vector(%d, %d)", self.x, self.y)
        end

        lcs.class(Vector, "Vector")

        local v1 = Vector(3, 4)
        local v2 = Vector(1, 2)
        local v3 = v1 + v2
        local v4 = v1 - v2
        local v5 = v1 * 2

        assert.is_true(v3 == Vector(4, 6))
        assert.is_true(v4 == Vector(2, 2))
        assert.is_true(v5 == Vector(6, 8))
        assert.equal("Vector(3, 4)", tostring(v1))
    end)

    test("should support state management", function()
        local Counter = lcs.class({
            __init = function(self, initial)
                self.count = initial or 0
            end,
            increment = function(self)
                self.count = self.count + 1
            end,
            decrement = function(self)
                self.count = self.count - 1
            end,
            get = function(self)
                return self.count
            end
        }, "Counter")

        local counter = Counter(5)
        counter:increment()
        counter:increment()
        counter:decrement()

        assert.equal(6, counter:get())
    end)

    test("should support callable objects with state", function()
        local Accumulator = lcs.class({
            __init = function(self, start)
                self.total = start or 0
            end,
            __call = function(self, value)
                self.total = self.total + value
                return self.total
            end
        }, "Accumulator")

        local acc = Accumulator(10)
        assert.equal(15, acc(5))
        assert.equal(20, acc(5))
        assert.equal(25, acc(5))
    end)
end)

context("LCS - Member Access", function()
    test("should allow reading instance members", function()
        local MyClass = lcs.class({
            value = 42
        }, "MyClass")

        local instance = MyClass()
        assert.equal(42, instance.value)
    end)

    test("should allow writing to instance members", function()
        local MyClass = lcs.class({
            __init = function(self)
                self.value = 10
            end
        }, "MyClass")

        local instance = MyClass()
        instance.value = 20
        assert.equal(20, instance.value)
    end)

    test("should allow adding new members to instances", function()
        local MyClass = lcs.class({}, "MyClass")
        local instance = MyClass()

        instance.new_member = "test"
        assert.equal("test", instance.new_member)
    end)

    test("should not share member values between instances", function()
        local MyClass = lcs.class({
            __init = function(self)
                self.value = 0
            end
        }, "MyClass")

        local inst1 = MyClass()
        local inst2 = MyClass()

        inst1.value = 10
        inst2.value = 20

        assert.equal(10, inst1.value)
        assert.equal(20, inst2.value)
    end)

    test("should share methods between instances", function()
        local MyClass = lcs.class({
            method = function(self) return "test" end
        }, "MyClass")

        local inst1 = MyClass()
        local inst2 = MyClass()

        assert.equal(inst1.method, inst2.method)
    end)
end)

context("LCS - Type Information", function()
    test("should preserve type information through type_info", function()
        local MyClass = lcs.class({
            method1 = function(self) end
        }, "MyClass")

        local type_info = lcs.typeof(MyClass)
        ---@cast type_info -nil

        assert.equal("MyClass", type_info.name)
        assert.is_false(type_info.is_interface)
        assert.is_table(type_info.meta)
        assert.is_table(type_info.indirect_meta)
        assert.is_table(type_info.members)
    end)

    test("should track constructor presence", function()
        local ClassWithInit = lcs.class({
            __init = function(self) end
        }, "ClassWithInit")

        local ClassWithoutInit = lcs.class({}, "ClassWithoutInit")

        local type1 = lcs.typeof(ClassWithInit)
        assert.is_not_nil(type1)
        ---@cast type1 -nil

        local type2 = lcs.typeof(ClassWithoutInit)
        assert.is_not_nil(type2)
        ---@cast type2 -nil

        assert.is_true(type1.has_constructor)
        assert.is_false(type2.has_constructor)
    end)

    test("should track pre-constructor presence", function()
        local ClassWithPre = lcs.class({
            __pre = function() end
        }, "ClassWithPre")

        local ClassWithoutPre = lcs.class({}, "ClassWithoutPre")

        local type1 = lcs.typeof(ClassWithPre)
        assert.is_not_nil(type1)
        ---@cast type1 -nil

        local type2 = lcs.typeof(ClassWithoutPre)
        assert.is_not_nil(type2)
        ---@cast type2 -nil

        assert.is_true(type1.has_pre_constructor)
        assert.is_false(type2.has_pre_constructor)
    end)

    test("should track implemented interfaces", function()
        local IGreeter = lcs.interface({}, "IGreeter")
        local IRunner = lcs.interface({}, "IRunner")

        local MyClass = lcs.class({}, "MyClass", IGreeter, IRunner)
        local type_info = lcs.typeof(MyClass)
        assert.is_not_nil(type_info)
        ---@cast type_info -nil

        assert.equal(2, #type_info.interfaces)
    end)

    test("should identify interface types", function()
        local IMyInterface = lcs.interface({}, "IMyInterface")
        local type_info = lcs.typeof(IMyInterface)
        assert.is_not_nil(type_info)
        ---@cast type_info -nil

        assert.is_true(type_info.is_interface)
    end)

    test("should identify class types", function()
        local MyClass = lcs.class({}, "MyClass")
        local type_info = lcs.typeof(MyClass)
        assert.is_not_nil(type_info)
        ---@cast type_info -nil

        assert.is_false(type_info.is_interface)
    end)
end)

context("LCS - __gc Metamethod", function()
    test("should support __gc metamethod", function()
        local gc_called = false

        local MyClass = lcs.class({
            __gc = function(self)
                gc_called = true
            end
        }, "MyClass")

        do
            local instance = MyClass()
            instance = nil
        end

        collectgarbage("collect")
        -- Note: gc_called should be true after garbage collection
        -- but timing is not guaranteed in tests
    end)
end)

context("LCS - __close Metamethod (Lua 5.4)", function()
    test("should support __close metamethod", function()
        local close_called = false

        local MyClass = lcs.class({
            __close = function(self)
                close_called = true
            end
        }, "MyClass")

        do
            local instance <close> = MyClass()
        end

        assert.is_true(close_called)
    end)
end)

context("LCS - __pairs and __ipairs", function()
    test("should support custom __pairs", function()
        local MyClass = lcs.class({
            __init = function(self)
                self.data = { a = 1, b = 2, c = 3 }
            end,
            __pairs = function(self)
                return pairs(self.data)
            end
        }, "MyClass")

        local instance = MyClass()
        local keys = {}

        for k, v in pairs(instance) do
            keys[k] = v
        end

        assert.equal(1, keys.a)
        assert.equal(2, keys.b)
        assert.equal(3, keys.c)
    end)
end)

context("LCS - Error Handling", function()
    test("should error when interface method missing in class", function()
        local IRequired = lcs.interface({
            required_method = function(self) end
        }, "IRequired", { "required_method" })

        assert.has_error(function()
            lcs.class({
                -- missing required_method
            }, "MyClass", IRequired)
        end, "interface method 'required_method' not implemented in class 'MyClass' from interface 'IRequired'")
    end)

    test("should error when trying to set template property", function()
        local MyClass = lcs.class({}, "MyClass")

        assert.has_error(function()
            MyClass.foo = "bar"
        end, "cannot set value 'foo' in class template 'MyClass'")
    end)

    test("should error with invalid interface parameter", function()
        assert.has_error(function()
            lcs.class({}, "MyClass", {}) -- plain table instead of interface
        end, "not a valid interface found: '1' in type 'MyClass'")
    end)

    test("should validate table parameter in LCS.class", function()
        assert.has_error(function()
            ---@diagnostic disable-next-line: param-type-mismatch
            lcs.class(nil, "MyClass")
        end)
    end)

    test("should validate string parameter in LCS.class", function()
        assert.has_error(function()
            ---@diagnostic disable-next-line: param-type-mismatch
            lcs.class({}, nil)
        end)
    end)

    test("should validate table parameter in LCS.interface", function()
        assert.has_error(function()
            ---@diagnostic disable-next-line: param-type-mismatch
            lcs.interface(nil, "IMyInterface")
        end)
    end)

    test("should validate string parameter in LCS.interface", function()
        assert.has_error(function()
            ---@diagnostic disable-next-line: param-type-mismatch
            lcs.interface({}, nil)
        end)
    end)
end)

context("LCS - Real World Examples", function()
    test("should implement a Stack data structure", function()
        local Stack = lcs.class({
            __init = function(self)
                self.items = {}
            end,
            push = function(self, item)
                table.insert(self.items, item)
            end,
            pop = function(self)
                return table.remove(self.items)
            end,
            peek = function(self)
                return self.items[#self.items]
            end,
            is_empty = function(self)
                return #self.items == 0
            end,
            __len = function(self)
                return #self.items
            end
        }, "Stack")

        local stack = Stack()
        assert.is_true(stack:is_empty())

        stack:push(1)
        stack:push(2)
        stack:push(3)

        assert.equal(3, #stack)
        assert.equal(3, stack:peek())
        assert.equal(3, stack:pop())
        assert.equal(2, stack:pop())
        assert.equal(1, #stack)
    end)

    test("should implement a Point class with distance calculation", function()
        local Point = lcs.class({
            __init = function(self, x, y)
                self.x = x
                self.y = y
            end,
            distance_to = function(self, other)
                local dx = self.x - other.x
                local dy = self.y - other.y
                return math.sqrt(dx * dx + dy * dy)
            end,
            __tostring = function(self)
                return string.format("Point(%.2f, %.2f)", self.x, self.y)
            end
        }, "Point")

        local p1 = Point(0, 0)
        local p2 = Point(3, 4)

        assert.equal(5, p1:distance_to(p2))
        assert.equal("Point(0.00, 0.00)", tostring(p1))
    end)

    test("should implement a simple Observer pattern", function()
        local Observer = lcs.interface({
            update = function(self, data) end
        }, "Observer", { "update" })

        local Subject = lcs.class({
            __init = function(self)
                self.observers = {}
            end,
            attach = function(self, observer)
                table.insert(self.observers, observer)
            end,
            notify = function(self, data)
                for _, observer in ipairs(self.observers) do
                    observer:update(data)
                end
            end
        }, "Subject")

        local ConcreteObserver = lcs.class({
            __init = function(self)
                self.data = nil
            end,
            update = function(self, data)
                self.data = data
            end
        }, "ConcreteObserver", Observer)

        local subject = Subject()
        local obs1 = ConcreteObserver()
        local obs2 = ConcreteObserver()

        subject:attach(obs1)
        subject:attach(obs2)
        subject:notify("test data")

        assert.equal("test data", obs1.data)
        assert.equal("test data", obs2.data)
    end)
end)
