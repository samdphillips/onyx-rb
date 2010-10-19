
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
        vm = doit('-1')
        assert_equal(-1, vm.tos)
    end

    def test_add
        vm = doit('3 + 4')
        assert_equal(7, vm.tos)
    end

    def test_add_mul
        vm = doit('3 + 4 * 2')
        assert_equal(14, vm.tos)
    end

    def test_ifTrue_ifFalse_true
        vm = doit('true ifTrue: [ 42 ] ifFalse: [ 0 ]')
        assert_equal(42, vm.tos)
    end

    def test_ifTrue_ifFalse_false
        vm = doit('false ifTrue: [ 42 ] ifFalse: [ 0 ]')
        assert_equal(0, vm.tos)
    end

end

