
require 'onyx'
require 'stringio'
require 'test/unit'

class TestParser < Test::Unit::TestCase
    include Onyx

    def parser_string(s)
        Parser.new(StringIO.new(s))
    end

    def assert_parse(p, expect)
        tree = p.parse_expr
        assert_equal(tree, expect)
    end

    def test_parse_int
        p = parser_string('42')
        assert_parse(p, EConst.new(42))
    end
end
