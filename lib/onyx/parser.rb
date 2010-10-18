
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
                parse_message
            else
                parse_error
            end
        end

        def parse_message
            r = parse_primary
            r = parse_unary(r)
            parse_binary(r)
            #parse_keyword(r)
        end

        def parse_primary
            if cur_tok.int? then
                v = cur_tok.value
                step
                EConst.new(v)
            else
                parse_error
            end
        end

        def parse_unary(r)
            while cur_tok.id? do
                r = ESend.new(r, cur_tok.value, [])
                step
            end
            r
        end

        def parse_binary(r)
            while cur_tok.binsel? do
                op = cur_tok.value
                step

                arg = parse_primary
                arg = parse_unary(arg)
                r = ESend.new(r, op, [arg])
            end
            r
        end
    end
end

