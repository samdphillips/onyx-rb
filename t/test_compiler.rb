
require 'onyx'
require 'stringio'
require 'test/unit'

class TestCompiler < Test::Unit::TestCase
    include Onyx

    def compile_string(s)
        ast = Parser.new(StringIO.new(s)).parse_expr
        Compiler.new.compile(ast)
    end

    def test_compile_int
        insts = compile_string('42')
        assert_equal(insts, [LDC.new(42)])
    end
end

