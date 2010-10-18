
require 'onyx'
require 'stringio'
require 'test/unit'

class TestLexer < Test::Unit::TestCase
    include Onyx

    def lex_string(s)
        Lexer.new(StringIO.new(s))
    end

    def assert_token(lex, type, value)
        tok = lex.next
        assert_instance_of(Token, tok, "Not a token")
        assert_equal(type, tok.type, "Incorrect type")
        assert_equal(value, tok.value, "Incorrect value")
    end

    def test_lex_int
        l = lex_string('1234')
        assert_token(l, :int, 1234)
    end

    def test_lex_space
        l = lex_string('    1234')
        assert_token(l, :int, 1234)
    end

    def test_lex_negative
        l = lex_string('-1')
        assert_token(l, :int, -1)
    end

    def test_lex_binsel
        l = lex_string('+')
        assert_token(l, :binsel, :+)
    end

    def test_lex_binsel_sub
        l = lex_string('-')
        assert_token(l, :binsel, :-)
    end
end

