
require 'onyx'
require 'stringio'
require 'test/unit'

class TestParser < Test::Unit::TestCase
    include Onyx

    def parser_string(s)
        Parser.new(StringIO.new(s))
    end

    def parser_for_file(fn)
        Parser.new(File.open('t/' + fn))
    end

    def test_parse_int
        p = parser_string('42')
        t = p.parse_expr

        assert_instance_of(ConstNode, t)
        assert_equal(42, t.value)
    end

    def test_parse_global_id
        p = parser_string('Object')
        t = p.parse_expr

        assert_instance_of(RefNode, t)
        v = t.var
        assert_instance_of(Symbol, v)
        assert_equal(:Object, v)
    end

    def test_parse_var_ref
        p = parser_string('x')
        t = p.parse_expr
        assert_instance_of(RefNode, t)
    end

    def test_parse_executable_code
        p = parser_string('| a b | ^ a + b')
        block = BlockNode.new()
        p.parse_executable_code(block)

        assert_equal(:a, block.temps[0])
        assert_equal(:b, block.temps[1])
        assert_equal(1, block.stmts.size)
        r = block.stmts[0]
        assert_instance_of(ReturnNode, r)
        e = r.expr
        assert_instance_of(SendNode, e)
        assert_same(e.rcvr.var, block.temps[0])
        m = e.message
        assert_instance_of(MessageNode, m)
        assert_equal(m.selector, :+)
        assert_same(m.args[0].var, block.temps[1])
    end

    def test_parse_true
        p = parser_string('true')
        t = p.parse_expr

        assert_instance_of(ConstNode, t)
        assert_equal(true, t.value)
    end

    def test_parse_keyword
        p = parser_string('x at: 10')
        t = p.parse_expr

        assert_instance_of(SendNode, t)
        m = t.message
        assert_instance_of(MessageNode, m)
        assert_equal(:'at:', m.selector)
        assert_instance_of(ConstNode, m.args[0])
        assert_equal(10, m.args[0].value)
    end

    def test_parse_prim
        p = parser_string('Object _new')
        t = p.parse_expr

        assert_instance_of(SendNode, t)
        assert_instance_of(PrimMessageNode, t.message)
        assert_equal(t.message.selector, :_new)

        p = parser_string('Array _new: 10')
        t = p.parse_expr

        assert_instance_of(SendNode, t)
        assert_instance_of(PrimMessageNode, t.message)
        assert_equal(t.message.selector, :'_new:')

    end

    def test_parse_cascade
        p = parser_string('Transcript nextPut: foo; nextPut: bar; nl')
        t = p.parse_expr

        assert_instance_of(CascadeNode, t)
        assert_equal(t.messages.size, 3)
    end

    def test_parse_block
        p = parser_string('[:a :b || c | c := a + b ]')
        t = p.parse_block

        assert_instance_of(BlockNode, t)
        assert_equal(2, t.args.size)
        assert_equal(1, t.temps.size)
        assert_equal(1, t.stmts.size)
    end

    def test_parse_class
        p = parser_for_file('test_class.ost')
        t = p.parse_class

        assert_instance_of(ClassNode, t)
        assert_equal(t.name, :Object)
        assert_instance_of(ConstNode, t.trait_expr)

        assert_instance_of(MethodNode, t.methods[0])
        assert_equal(:gar, t.methods[0].name)
        assert_equal(0, t.methods[0].args.size)
        assert_equal(0, t.methods[0].temps.size)
        assert_equal(1, t.methods[0].stmts.size)
        assert_instance_of(ReturnNode, t.methods[0].stmts[0])

        assert_instance_of(Symbol, t.methods[1].stmts[0].expr.var)
        assert_instance_of(Symbol, t.meta[0].methods[0].stmts[0].expr.var)
    end

    def test_parse_trait
        p = parser_for_file('test_trait.ost')
        t = p.parse_trait

        assert_instance_of(TraitNode, t)
        assert_instance_of(Symbol, t.methods[0].stmts[0].var)
        assert_instance_of(Symbol, t.methods[1].stmts[0].rcvr.var)
    end

    def test_parse_extension
        p = parser_for_file('test_extension.ost')
        t = p.parse_extension

        assert_instance_of(ClassExtNode, t)
    end

    def test_parse_import
        p = parser_string("import: 'system'")
        t = p.parse_import
        assert_instance_of(ImportNode, t)
        assert_equal(t.name, :system)
    end

end
