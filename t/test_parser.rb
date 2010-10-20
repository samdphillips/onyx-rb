
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
        assert_equal(1, stmts.size)
        r = stmts[0]
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
end
