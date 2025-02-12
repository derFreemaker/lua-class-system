package.path = "./?.lua;" .. package.path
local luaunit = require("tests.Luaunit")

local class_system = require("src.init")

function TestCreateClass()
    local test = class_system.create({}, { name = "create-empty" })

    luaunit.assertNotIsNil(test)
end

function TestCreateClassWithBaseClass()
    local test_base_class = class_system.create({}, { name = "test-base-class" })
    local test = class_system.create({}, { name = "create_emtpy_test-class", BaseClass = test_base_class })

    luaunit.assertNotIsNil(test)
end

function TestConstructClass()
    local test = class_system.create({}, { name = "test-class" })

    luaunit.assertNotIsNil(test())
end

function TestExtendClass()
    local test = class_system.create({}, { name = "test-class" })
    local test_class_instance = test()

    local test_base_class = class_system.create({}, { name = "test-base-class", inherit = test })
    local test_base_class_instance = test_base_class()

    local extended = class_system.extend(test, { test = "hi" })

    local extended_test_class_instance = test()
    local extended_test_base_class_instance = test_base_class()
    local extended_class_instance = extended()

    luaunit.assertEquals(test_class_instance.test, "hi")
    luaunit.assertEquals(test_base_class_instance.test, "hi")
    luaunit.assertEquals(extended_test_class_instance.test, "hi")
    luaunit.assertEquals(extended_test_base_class_instance.test, "hi")
    luaunit.assertEquals(extended_class_instance.test, "hi")
end

function TestDeconstructClass()
    local class_name = "test-class"

    local test_class = class_system.create({}, { name = class_name })
    local test = test_class()
    local function error_because_of_deconstructed_class()
        _ = test.hi
    end

    class_system.deconstruct(test)

    luaunit.assertErrorMsgContains("cannot get values from deconstruct class: " .. class_name,
        error_because_of_deconstructed_class)
end

function TestPreConstructor()
    local uniqe_value = {}

    local test_class = class_system.create({
        __preinit = function()
            return uniqe_value
        end
    }, { name = "test_class" })

    luaunit.assertIsTrue(test_class() == uniqe_value, "did not return expected object from '__preinit'")
end

function TestNotCallingBaseConstructor()
    local base_class = class_system.create({
        __init = function()
            error("constructor called")
        end
    }, { name = "base_class" })

    local test_class = class_system.create({}, { name = "test_class", inherit = base_class })

    luaunit.assertErrorMsgMatches(".*: '[a-z._]*' constructor did not invoke '[a-z._]*' %(base%) constructor", test_class)
end

os.exit(luaunit.LuaUnit.run())
