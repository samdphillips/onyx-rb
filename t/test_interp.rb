
require 'onyx'
require 'stringio'
require 'test/unit'

class TestInterp < Test::Unit::TestCase
    include Onyx

    def setup
        @terp = Interpreter.boot
    end

    def test_boot
        assert(@terp.globals.include?(:Object))
        assert(@terp.globals.include?(:Interval))
    end

    def assert_interp(s, result)
        assert_equal(result, @terp.eval_string(s))
    end

    def test_sends
        assert_interp("3 + 4", 7)
        assert_interp("3 + 4 * 2", 14)
        assert_interp("3 isNumber", true)
        assert_interp("3 = 3", true)
        assert_interp("3 = 4", false)

        assert_interp("3 // 4", 0)
        assert_interp("8 // 4", 2)
        assert_interp("9 // 4", 2)
        assert_interp("6 // 4", 1)
    end

    def test_compare
        [:<, :>, :<=, :>=].each do | s |
            (1..3).each do | i |
                (1..3).each do | j |
                    assert_interp("#{i} #{s} #{j}", i.send(s, j))
                end
            end
        end
    end

    def test_assign
        assert_interp("a := 3. a", 3)
    end

    def test_instance_creation
        @terp.eval_string("a := 3 -> 4")
        assert_interp("k := a key", 3)
        assert_interp("v := a value", 4)
        assert_interp("key", nil)
        assert_interp("value", nil)
    end

    def test_blocks
        assert_interp("[ 3 ] value", 3)
        assert_interp("[:a | a ] value: 10", 10)
        assert_interp("a := 0. [:a | a ] value: 10", 10)
    end

    def test_conditional
        assert_interp("true  ifTrue: [ 10 ]", 10)
        assert_interp("false ifTrue: [ 10 ]", nil)
        assert_interp("true  ifTrue: [ 10 ] ifFalse: [ 11 ]", 10)
        assert_interp("false ifTrue: [ 10 ] ifFalse: [ 11 ]", 11)
    end

    def test_loops
        assert_interp("n := 0. [ n < 10 ] whileTrue: [ n := n + 1 ]", nil)
        assert_interp("n := 0. [ n < 10 ] whileTrue: [ n := n + 1 ]. n", 10)
        assert_interp("n := 0. [ n = 10 ] whileFalse: [ n := n + 1 ]. n", 10)
    end

    def test_arrays
        assert_interp("(Array new: 10) size", 10)
        assert_interp("Array new size", 0)
        assert_interp("a := Array new: 1. a at: 0 put: 10. a at: 0", 10)
        assert_interp("a := Array with: 10. a at: 0", 10)
    end

    def test_intervals
        @terp.eval_string("i := 1 to: 10")
        assert_interp("i start",  1)
        assert_interp("i stop",  10)
        assert_interp("i step",   1)

        @terp.eval_string("i := 10 to: 1")
        assert_interp("i start", 10)
        assert_interp("i stop",   1)
        assert_interp("i step",  -1)

        @terp.eval_string("i := 1 to: 10")
        assert_interp("i asArray", [1,2,3,4,5,6,7,8,9,10])
    end
end

