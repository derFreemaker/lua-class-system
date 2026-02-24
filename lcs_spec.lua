local lcs = require("lcs")

context("type", function()
    test("class", function()
        local class = lcs.class({}, "class")

        assert.equal("type(class)", tostring(lcs.typeof(class)))
    end)

    test("interface", function()
        local interface = lcs.interface({}, "interface")

        assert.equal("type(interface)", tostring(lcs.typeof(interface)))
    end)

    test("sealed", function()
        local class = lcs.class({}, "class")
        local type_info = lcs.typeof(class)

        assert.has_error(function()
            ---@diagnostic disable-next-line: inject-field
            type_info.some_value = "wtf"
        end, "type information is a sealed table")
    end)
end)

context("class", function()
    test("simple", function()
        local class = lcs.class({}, "simple")
        local instance = class()

        assert.equal("template(simple)", tostring(class))
        assert.equal("class(simple)", tostring(instance))
    end)

    test("template members", function()
        local works = false
        local template_member = lcs.class({
            work = function()
                works = true
            end,
        }, "template")

        template_member.work()
        assert.equal(true, works)

        assert.has_error(function()
            template_member.work = 123
        end, "cannot set value 'work' in class template 'template'")
    end)

    test("instance member", function()
        local class = lcs.class({
            work = function(self)
                self.works = true
            end,
        }, "class")

        local instance = class()
        instance:work()
        assert.equal(true, instance.works)
    end)

    test("interface member over template", function()
        local interface = lcs.interface({
            some = function()
                return 946
            end,
        }, "interface")

        local class = lcs.class({}, "class", interface)
        assert.equal(946, class.some())
    end)

    test("pre constructor with return", function()
        local class = lcs.class({
            __pre = function()
                return true, 451
            end,
        }, "class")

        local instance = class()
        assert.equal(451, instance)
    end)

    test("pre constructor without return", function()
        local class = lcs.class({
            __pre = function()
                return false, 451
            end,
        }, "class")

        local instance = class()
        assert.no.equal(451, instance)
    end)

    test("constructor", function()
        local class = lcs.class({
            __init = function(self, value)
                self.test = value
            end,
        }, "constructor")

        local tbl = {}
        local instance = class(tbl)
        assert.equal(tbl, instance.test)
    end)

    test("meta", function()
        local class = lcs.class({
            __index = function(_, value)
                return value
            end,
            __newindex = function()
                error("fail custom")
            end,
        }, "meta")

        local instance = class()
        local tbl = {}
        assert.equal(tbl, instance[tbl])
        assert.has_error(function()
            instance.test = 123
        end, "fail custom")
    end)

    test("operator", function()
        local class
        class = lcs.class({
            __init = function(self, value)
                self.test = value
            end,
            __sub = function(a, b)
                return class(a.test - b.test)
            end,
        }, "operator")

        local a = class(1)
        local b = class(7)
        local c = a - b
        assert.equal(-6, c.test)
    end)

    test("implementing", function()
        local interface = {
            parent_method = function()
                return lcs.interface_method()
            end,
        }
        lcs.interface(interface, "interface", { interface.parent_method })

        assert.has_error(function()
            lcs.class({}, "class", interface)
        end, "interface method 'parent_method' not implemented in class 'class' from interface 'interface'")
    end)

    test("overridding", function()
        local interface = lcs.interface({
            method = function()
                return 123
            end,
        }, "interface")

        assert.has_error(function()
            lcs.class({
                method = function()
                    return 321
                end,
            }, "class", interface)
        end, "overriding member 'method' in class 'class' from interface 'interface' is not allowed")
    end)
end)

context("interface", function()
    test("simple", function()
        local interface = lcs.interface({}, "simple", nil)

        assert.has_error(function()
            interface()
        end, "cannot construct interface 'simple'")
        assert.equal("interface(simple)", tostring(interface))
    end)

    test("simple with empty interfaceing methods", function()
        local interface = lcs.interface({}, "simple", {})

        assert.has_error(function()
            interface()
        end, "cannot construct interface 'simple'")
        assert.equal("interface(simple)", tostring(interface))
        assert.equal("type(simple)", tostring(lcs.typeof(interface)))
    end)

    test("member", function()
        local tbl = {}
        local interface = lcs.interface({
            test_member = function()
                return tbl
            end,
        }, "member")

        assert.equal(tbl, interface.test_member())
    end)

    test("meta", function()
        assert.has_error(function()
            lcs.interface({
                __add = function()
                    return 1
                end
            }, "meta")
        end, "cannot add meta method '__add' to an interface 'meta'")
    end)

    test("implement", function()
        local a = {
            child = function()
                return lcs.interface_method()
            end,
            parent = function(self)
                return self:child()
            end,
        }
        lcs.interface(a, "a", { a.child })

        local b = lcs.interface({
            child = function()
                return 673
            end,
        }, "b", {}, a)

        assert.equal(673, b:parent())
    end)

    test("invalid interface tbl", function()
        assert.has_error(function()
            local interface = {
                some = function()
                    return lcs.interface_method()
                end,
            }

            -- we disable it here since its intended to fail
            ---@diagnostic disable-next-line: param-type-mismatch
            lcs.interface(interface, "interface", 123)
        end, "#3 expected table, got number")
    end)

    test("invalid interface method", function()
        assert.has_error(function()
            local interface = {
                some = 123
            }

            -- we disable it here since its intended to fail
            ---@diagnostic disable-next-line: assign-type-mismatch
            lcs.interface(interface, "interface", { interface.some })
        end, "not a valid interface method found type: 'number' in type 'interface'")
    end)

    test("malformed interface structure", function()
        local a = {
            child = function() end,
        }
        lcs.interface(a, "a", { a.child })

        local b = lcs.interface({
            child = function()
                return 123
            end,
        }, "b")

        assert.has_error(function()
            lcs.interface({}, "c", {}, a, b)
        end, "implementing method 'child' from interface 'b' which doesn't implement interface 'a'")

        assert.has_error(function()
            lcs.class({}, "c", a, b)
        end, "implementing method 'child' from interface 'b' which doesn't implement interface 'a'")
    end)

    test("provided only interfaces", function()
        assert.has_error(function()
            lcs.class({}, "interfaces", {})
        end, "not a valid interface found: '1' in type 'interfaces'")
    end)
end)
