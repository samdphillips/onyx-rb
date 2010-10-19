
module Onyx
    class ParseError < Exception
        attr_reader :message

        def initialize(parser, message='')
            @parser = parser
            @message = message
        end
    end

    class Parser
        attr_reader :cur_tok, :globals, :scope

        def initialize(io)
            @lex = Lexer.new(io)
            @globals = GScope.new
            @scope = @globals
            step
        end

        def step
            @cur_tok = @lex.next
        end

        def parse_error(message='')
            raise ParseError.new(self, message)
        end

        def expect(type, value=nil)
            if cur_tok.type != type then
                parse_error("Expected #{type}")
            elsif !value.nil? then
                if value != cur_tok.value
                    parse_error("Expected #{value}")
                end
            end
            step
        end

        def lookup_var(name)
            @scope.lookup_var(name)
        end

        def push_scope
            @scope = Env.new(@scope)
        end

        def pop_scope
            @scope = @scope.parent
        end

        def parse_executable_code
            temps = parse_temps
            push_scope
            temps.each {|v| @scope.add_var(v)}
            stmts = parse_statements
            pop_scope
            EBody.new(temps, stmts)
        end

        def parse_temps
            temps = []

            if cur_tok.binsel? and cur_tok.value == :'|' then
                step

                while cur_tok.id? do
                    temps << TVar.new(cur_tok.value)
                    step
                end

                expect(:binsel, :'|')
            end
            temps
        end

        def parse_statements
            stmts = []

            while true do
                if cur_tok.one_of [:caret, :int, :id] then
                    stmts << parse_statement
                else
                    break
                end
                
                if cur_tok.dot? then
                    step
                else
                    break
                end
            end
            stmts
        end

        def parse_statement
            if cur_tok.caret? then
                parse_return
            elsif cur_tok.one_of [:int, :id] then
                parse_expr
            else
                parse_error
            end
        end

        def parse_return
            expect(:caret)
            EReturn.new(parse_expr)
        end

        def parse_expr
            if cur_tok.int? then
                parse_message
            elsif cur_tok.id? then
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
            elsif cur_tok.id? then
                name = cur_tok.value
                step
                ERef.new(lookup_var(name))
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

