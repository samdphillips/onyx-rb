
require 'onyx'
require 'test/unit'

class TestAssembler < Test::Unit::TestCase
    include Onyx

    def assemble(ops)
        a = Assembler.new
        a.assemble(ops)
    end

    def test_assemble_LDC_lit
        m = assemble([LDC.new(42)])
        assert_equal(Method.new("\x00", [42]), m)
    end

    def test_assemble_LDC_special
        m = assemble([LDC.new(0)])
        assert_equal(Method.new("\x0A", []), m)

        m = assemble([LDC.new(1)])
        assert_equal(Method.new("\x0B", []), m)

        m = assemble([LDC.new(-1)])
        assert_equal(Method.new("\x0C", []), m)

        m = assemble([LDC.new(true)])
        assert_equal(Method.new("\x0D", []), m)

        m = assemble([LDC.new(false)])
        assert_equal(Method.new("\x0E", []), m)

        m = assemble([LDC.new(nil)])
        assert_equal(Method.new("\x0F", []), m)
    end

    def test_halt
        m = assemble([HALT])
        assert_equal(Method.new("\xFF", []), m)
    end
end
