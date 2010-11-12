
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
    end
end

