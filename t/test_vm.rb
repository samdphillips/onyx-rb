
require 'onyx'
require 'test/unit'

class TestVm < Test::Unit::TestCase
    include Onyx

    def doit(s, trace=false)
        vm = OVM.new
        vm.trace = trace
        vm.doit(s)
    end

    def test_const_int
        vm = doit('42')
        assert_equal(42, vm.tos)
    end

    def test_const_int_special
        vm = doit('0')
        assert_equal(0, vm.tos)
        vm = doit('1')
        assert_equal(1, vm.tos)
        vm = doit('true')
        assert_equal(true, vm.tos)
        vm = doit('false')
        assert_equal(false, vm.tos)
        vm = doit('nil')
        assert_equal(nil, vm.tos)
    end

    def test_add
        vm = doit('3 + 4')
        assert_equal(7, vm.tos)
    end

    def xtest_add_mul
        vm = doit('3 + 4 * 2')
        assert_equal(14, vm.tos)
    end

    def xtest_ifTrue_ifFalse_true
        vm = doit('true ifTrue: [ 42 ] ifFalse: [ 0 ]')
        assert_equal(42, vm.tos)
    end

    def xtest_ifTrue_ifFalse_false
        vm = doit('false ifTrue: [ 42 ] ifFalse: [ 0 ]')
        assert_equal(0, vm.tos)
    end

    def xtest_factorial
        vm = OVM.new
        vm.add_method(:SmallInteger,
            "factorial [ | a n | [ n = 1 ] whileFalse: [ a := a * n. n := n - 1. ]. ^a ]")
        vm.doit('5 factorial')
        assert_equal(120, vm.tos)
    end

end

