
require 'onyx'
require 'stringio'
require 'test/unit'

class TestInterp < Test::Unit::TestCase
    include Onyx

    def setup
        @terp = Interpreter.boot
    end

    def assert_interp(s, result)
        assert_equal(result, @terp.eval_string(s))
    end

    def test_compare
        assert_interp("1 < 1", false)
        assert_interp("1 < 2", true)
        assert_interp("1 < 3", true)
        assert_interp("2 < 1", false)
        assert_interp("2 < 2", false)
        assert_interp("2 < 3", true)
        assert_interp("3 < 1", false)
        assert_interp("3 < 2", false)
        assert_interp("3 < 3", false)
        assert_interp("1 > 1", false)
        assert_interp("1 > 2", false)
        assert_interp("1 > 3", false)
        assert_interp("2 > 1", true)
        assert_interp("2 > 2", false)
        assert_interp("2 > 3", false)
        assert_interp("3 > 1", true)
        assert_interp("3 > 2", true)
        assert_interp("3 > 3", false)
        assert_interp("1 <= 1", true)
        assert_interp("1 <= 2", true)
        assert_interp("1 <= 3", true)
        assert_interp("2 <= 1", false)
        assert_interp("2 <= 2", true)
        assert_interp("2 <= 3", true)
        assert_interp("3 <= 1", false)
        assert_interp("3 <= 2", false)
        assert_interp("3 <= 3", true)
        assert_interp("1 >= 1", true)
        assert_interp("1 >= 2", false)
        assert_interp("1 >= 3", false)
        assert_interp("2 >= 1", true)
        assert_interp("2 >= 2", true)
        assert_interp("2 >= 3", false)
        assert_interp("3 >= 1", true)
        assert_interp("3 >= 2", true)
        assert_interp("3 >= 3", true)
    end

    def test_instance_creation
        @terp.eval_string("a := 3 -> 4")
        assert_interp("k := a key", 3)
        assert_interp("v := a value", 4)
        assert_interp("key", nil)
        assert_interp("value", nil)
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
    end

    def test_string
        assert_interp("'abc', '123'", "abc123")
        assert_interp("('abc' at: 0) codePoint", 97)

        @terp.eval_string("foo := 'abc'")
        assert_interp("(foo at: 0) == (foo at: 0)", true)

        assert_interp("(String new: 1) size", 1)
        assert_interp("(((String new: 1) at: 0 put: $a; yourself) at: 0) codePoint", 97)
    end

    def test_character
        @terp.eval_string("a1 := Character codePoint: 97")
        @terp.eval_string("a2 := Character codePoint: 97")
        assert_interp("a1 == a2", true)

        assert_interp("$a == (Character codePoint: 97)", true)
        assert_interp("('a' at: 0) == (Character codePoint: 97)", true)
        assert_interp("(#($a) at: 0) == (Character codePoint: 97)", true)
        assert_interp("$a == $b", false)
        assert_interp("$  codePoint", 32)
        assert_interp("$a asLowercase == $a", true)
        assert_interp("$A asLowercase == $a", true)
        assert_interp("$  asLowercase == $ ", true)
        assert_interp("$A asString", 'A')
    end

    def test_symbol
        assert_interp("#a", :a)
        assert_interp("#a asString", 'a')
        assert_interp("'abc' asSymbol", :abc)
        assert_interp("#a == #a", true)
        assert_interp("#a == 'a' asSymbol", true)
    end

    def test_continuations
        assert_interp("p := PromptTag new. [ 2 + 5 ] withPrompt: p", 7)
        assert_interp(
            "p := PromptTag new. [ 2 + ([:k | 5 ] withCont: p) ] withPrompt: p", 7)
        assert_interp(
            "p := PromptTag new. [ 2 + ([:k | k value: 5 ] withCont: p) ] withPrompt: p", 9)
        assert_interp(
            "p := PromptTag new. [ 2 + (p abort: 0) + 5 ] withPrompt: p", 0)

        assert_interp(
            "p := PromptTag new. [ 2 + ([ 3 + ([:k | k value: 2 ] withCont: p) ] withPrompt: p) ] withPrompt: p", 10)

        assert_interp(
            "p := PromptTag new.
             [ 2 + ([:k | p abort: k ] withCont: p) ]
                 withPrompt: p
                 abort: [:x | x value: 3 ]", 5)
    end

    def test_marks
        assert_interp("[ 3 + 4 ] withMark: #foo value: #bar", 7)
        assert_interp(
            "cmark := ContinuationMark new. 
             p := PromptTag new.
             [ [ 3 + (cmark firstMark: p) ] 
                   withMark: cmark 
                   value: 4 ] withPrompt: p", 7)
    end
end

