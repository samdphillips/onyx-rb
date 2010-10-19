
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

        assert_instance_of(EConst, t)
        assert_equal(42, t.value)
    end

    def test_parse_global_id
        p = parser_string('Object')
        t = p.parse_expr

        assert_instance_of(ERef, t)
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
        assert_instance_of(ERef, t)
        assert_same(v, t.var)
    end

    def test_parse_executable_code
        p = parser_string('| a b | ^ a + b')
        t = p.parse_executable_code

        assert_equal(:a, t.temps[0].name)
        assert_equal(:b, t.temps[1].name)
        assert_equal(1, t.stmts.size)
        r = t.stmts[0]
        assert_instance_of(EReturn, r)
        e = r.expr
        assert_instance_of(ESend, e)
        assert_same(e.rcvr.var, t.temps[0])
        assert_same(e.args[0].var, t.temps[1])
    end

    def test_parse_true
        p = parser_string('true')
        t = p.parse_expr

        assert_instance_of(EConst, t)
        assert_equal(true, t.value)
    end

    def test_parse_keyword
        p = parser_string('x at: 10')
        t = p.parse_expr

        assert_instance_of(ESend, t)
        assert_equal(:'at:', t.msg)
        assert_instance_of(EConst, t.args[0])
        assert_equal(10, t.args[0].value)
    end
end
