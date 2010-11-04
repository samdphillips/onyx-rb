
require 'onyx'
require 'stringio'
require 'test/unit'

class TestParser < Test::Unit::TestCase
    include Onyx

    def parser_string(s)
        Parser.new(StringIO.new(s))
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
        assert_instance_of(GVar, v)
        assert_equal(:Object, v.name)
        assert(p.globals.include?(v), "Var not in globals")
    end

    def test_parse_ivar_id
        p = parser_string('x')
        p.push_scope
        v = IVar.new(:x)
        p.scope.add_var(v)

        t = p.parse_expr
        assert_instance_of(RefNode, t)
        assert_same(v, t.var)
    end

    def test_parse_executable_code
        p = parser_string('| a b | ^ a + b')
        temps,stmts = p.parse_executable_code

        assert_equal(:a, temps[0].name)
        assert_equal(:b, temps[1].name)
        assert_equal(1, stmts.exprs.size)
        r = stmts.exprs[0]
        assert_instance_of(ReturnNode, r)
        e = r.expr
        assert_instance_of(MessageNode, e)
        assert_same(e.rcvr.var, temps[0])
        assert_same(e.args[0].var, temps[1])
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

        assert_instance_of(MessageNode, t)
        assert_equal(:'at:', t.msg)
        assert_instance_of(ConstNode, t.args[0])
        assert_equal(10, t.args[0].value)
    end

    def test_parse_prim
        p = parser_string('Object _new')
        t = p.parse_expr

        assert_instance_of(PrimMessageNode, t)
        assert_equal(:_new, t.msg)

        p = parser_string('Array _new: 10')
        t = p.parse_expr

        assert_instance_of(PrimMessageNode, t)
        assert_equal(:'_new:', t.msg)

    end

    def test_parse_block
        p = parser_string('[:a :b || c | c := a + b ]')
        t = p.parse_block

        assert_instance_of(BlockNode, t)
        assert_equal(2, t.args.size)
        assert_equal(1, t.temps.size)
        assert_equal(1, t.stmts.exprs.size)
    end
end
