
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

    def test_ordered_collections
        @terp.eval_string("c := OrderedCollection new")
        assert_interp("c size", 0)
        assert_interp("c asArray", [])

        @terp.eval_string("c add: 0")
        assert_interp("c size", 1)
        assert_interp("c asArray", [0])

        @terp.eval_string("c add: 1")
        assert_interp("c size", 2)
        assert_interp("c asArray", [0, 1])

        @terp.eval_string("c addFirst: 2")
        assert_interp("c size", 3)
        assert_interp("c asArray", [2, 0, 1])

        @terp.eval_string("c := OrderedCollection new")
        @terp.eval_string("1 to: 20 do: [:i | c addFirst: i ]")
        assert_interp("c asArray", [20, 19, 18, 17, 16, 15, 14, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1])

        @terp.eval_string("c := OrderedCollection new")
        @terp.eval_string("1 to: 20 do: [:i | c add: i ]")
        assert_interp("c asArray", [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20])
    end

    def test_string
        assert_interp("'abc', '123'", "abc123")
        assert_interp("('abc' at: 0) codePoint", ?a)

        @terp.eval_string("foo := 'abc'")
        assert_interp("(foo at: 0) == (foo at: 0)", true)
    end

    def test_character
        @terp.eval_string("a1 := Character codePoint: 97")
        @terp.eval_string("a2 := Character codePoint: 97")
        assert_interp("a1 == a2", true)

        assert_interp("$a == (Character codePoint: 97)", true)
        assert_interp("$a == $b", false)
        assert_interp("$  codePoint", 32)
    end

    def test_symbol
        assert_interp("#a", :a)
        assert_interp("#a asString", 'a')
        assert_interp("'abc' asSymbol", :abc)
        assert_interp("#a == #a", true)
        assert_interp("#a == 'a' asSymbol", true)
    end
end

