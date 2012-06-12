
require 'rspec'
require 'stringio'
require 'onyx'

class Symbol
    def to_token
        Onyx::Token.new(self)
    end
end

class Array
    def to_token
        Onyx::Token.new(self[0], self[1])
    end
end

module OnyxRSpecMatchers
    class Lex
        def initialize(str)
            @str = str
        end

        def to_tokens(*toks)
            MatchTokens.new(@str, toks)
        end

        def to_token(type, value=nil)
            MatchTokens.new(@str, [[type, value]])
        end

        def matches?(lexer)
            lexer.io = StringIO.new(@str)
            tok = nil
            begin
                while tok.nil? or tok.type != :eof do
                    tok = lexer.next
                end
                true
            rescue Onyx::LexError => e
                @result = e.message
                false
            end
        end

        def failure_message_for_should
            "expected lexer to complete got: #{@result}"
        end
    end

    class MatchTokens
        def initialize(str, toks)
            @str = str
            @toks = toks.collect { |tok| tok.to_token }
        end

        def matches?(lexer)
            lexer.io = StringIO.new(@str)

            @toks.each do | tok |
                ltok = lexer.next
                ltok.type.should == tok.type
                unless tok.value.nil? then
                    ltok.value.should == tok.value
                end
            end

            lexer.next.type.should == :eof
        end
    end

    def lex(str)
        Lex.new(str)
    end
end

RSpec::Matchers.define(:interpret) do | input, val |
    match do | terp |
        terp.eval_string(input).eql? val
    end
end

RSpec::Matchers.define(:interpret_script) do | file_name, val |
    match do | terp |
        node = Onyx::Parser.parse_file(file_name)
        terp.eval(node).eql? val
    end
end

# RSpec::Matchers.define(:lex) do | input |
#     match do | lexer |
#         lexer.io = StringIO.new(input)
#         toks = []
# 
#         tok = nil
#         while tok.nil? or tok.type != :eof do
#             tok = lexer.next
#             toks << tok
#         end
# 
#         toks.size should == @tok_types.size
#     end
# 
#     chain(:to_types) do | ttypes |
#         @tok_types = ttypes
#     end
#     
# end
