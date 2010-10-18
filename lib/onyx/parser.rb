
module Onyx
    class Parser
        attr_reader :cur_tok

        def initialize(io)
            @lex = Lexer.new(io)
            step
        end

        def step
            @cur_tok = @lex.next
        end

        def parse_expr
            if cur_tok.int? then
                EConst.new(cur_tok.value)
            else
                parse_error
            end
        end
    end
end

