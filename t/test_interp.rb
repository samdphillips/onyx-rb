
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
end

