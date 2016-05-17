
require 'onyx'
require 'stringio'
require 'test/unit'

class TestParser < Test::Unit::TestCase
    include Onyx

    def parser_string(s)
        Parser.new(StringIO.new(s))
    end

    def parser_for_file(fn)
        Parser.new(File.open('t/parser_tests/' + fn))
    end

    def test_parse_int
        p = parser_string('42')
        t = p.parse_expr

        assert_instance_of(ConstNode, t)
        assert_equal(42, t.value)
    end

    def test_parse_symbol
        p = parser_string('#test')
        t = p.parse_expr

        assert_instance_of(ConstNode, t)
        assert_equal(:test, t.value)
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

    def test_parse_literal_array
        p = parser_string("#(1 $c 'string' symbol #symbol)")
        t = p.parse_expr
        assert_instance_of(ConstNode, t)
        assert_equal(t.value.size, 5)
        assert_equal(t.value[0], 1)
        assert_instance_of(Char, t.value[1])
        assert_equal(t.value[1].code_point, 99)
        assert_equal(t.value[2], 'string')
        assert_equal(t.value[3], :symbol)
        assert_equal(t.value[4], :symbol)
    end

    def test_parse_expr_array
        p = parser_string("{ 3 + 4. #foo }")
        t = p.parse_expr
        assert_instance_of(CascadeNode, t)
        assert_equal(t.messages.size, 3)
    end

    def test_parse_empty_expr_array
        p = parser_string("{ }")
        t = p.parse_expr
        assert_instance_of(SendNode, t)
        assert_equal(:Array, t.rcvr.var)
        assert_equal(:'new:', t.message.selector)
        assert_equal(0, t.message.args[0].value)
    end

    def test_parse_nested
        p = parser_string('(x + y)')
        t = p.parse_expr
        assert_instance_of(SendNode, t)

        p = parser_string('(self = anObject) not')
        t = p.parse_expr
        assert_instance_of(SendNode, t)
        assert_equal(:not, t.message.selector)

        p = parser_string('[ (x foo) bar ]')
        t = p.parse_expr
        assert_instance_of(BlockNode, t)
        assert_equal(1, t.stmts.nodes.size)
        assert_instance_of(SendNode, t.stmts.nodes[0])
        assert_equal(:bar, t.stmts.nodes[0].message.selector)
    end

    def test_parse_executable_code
        p = parser_string('| a b | ^ a + b')
        block = BlockNode.new()
        p.parse_executable_code(block)

        assert_equal(:a, block.temps[0])
        assert_equal(:b, block.temps[1])
        assert_equal(1, block.stmts.nodes.size)
        r = block.stmts.nodes[0]
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
        assert_equal(1, t.stmts.nodes.size)
    end

    def test_parse_class
        p = parser_for_file('test_class.ost')
        t = p.parse_class

        assert_instance_of(ClassNode, t)
        assert_equal(t.name, :Object)
        assert_instance_of(SendNode, t.trait_expr)
        assert_instance_of(RefNode, t.trait_expr.rcvr)
        assert_equal(:TA, t.trait_expr.rcvr.var)

        assert_equal(2, t.meths.size)
        assert_instance_of(MethodNode, t.meths[0])
        assert_equal(:gar, t.meths[0].name)
        assert_equal(0, t.meths[0].args.size)
        assert_equal(0, t.meths[0].temps.size)
        assert_equal(1, t.meths[0].stmts.nodes.size)
        assert_instance_of(ReturnNode, t.meths[0].stmts.nodes[0])

        assert_instance_of(Symbol, t.meths[1].stmts.nodes[0].expr.var)
        assert_instance_of(Symbol, 
            t.meta.meths[0].stmts.nodes[0].expr.var)
    end

    def test_parse_trait
        p = parser_for_file('test_trait.ost')
        t = p.parse_trait

        assert_instance_of(TraitNode, t)
        assert_instance_of(Symbol, t.meths[0].stmts.nodes[0].var)
        assert_instance_of(Symbol, t.meths[1].stmts.nodes[0].rcvr.var)
    end


    def test_parse_import
        p = parser_string("import: 'system'")
        t = p.parse_import
        assert_instance_of(ImportNode, t)
        assert_equal(t.name, :system)
    end

    def test_parse_module
        p = parser_for_file('test_module.ost')
        t = p.parse_module

        assert_instance_of(SeqNode, t)
        assert_equal(7, t.nodes.size)
        assert_instance_of(ImportNode,   t.nodes[0])
        assert_instance_of(ImportNode,   t.nodes[1])
        assert_instance_of(ClassNode,    t.nodes[2])
        assert_instance_of(TraitNode,    t.nodes[3])
        assert_instance_of(AssignNode,   t.nodes[4])
        assert_instance_of(SendNode,     t.nodes[5])
        assert_instance_of(SendNode,     t.nodes[6])
    end

end
