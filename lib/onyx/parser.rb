
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
            @stack = []
            step
        end

        def push_token(tok)
            @stack << tok
        end

        def step
            if @stack == [] then
                @cur_tok = @lex.next
            else
                @stack.shift
            end
        end

        def cur_tok
            if @stack == [] then
                @cur_tok
            else
                @stack[0]
            end
        end

        def parse_error(message='')
            raise ParseError.new(self, message)
        end

        def expect(type, value=nil)
            if cur_tok.type != type then
                parse_error("Expected #{type} got #{cur_tok.type}")
            elsif !value.nil? then
                if value != cur_tok.value
                    parse_error("Expected #{value} got #{cur_tok.value}")
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

        def parse_method
            name, args = parse_method_header
            expect(:lsq)
            push_scope
            args.each {|v| @scope.add_var(v)}
            body = parse_executable_code
            pop_scope
            expect(:rsq)
            MethodNode.new(name, args, body)
        end

        def parse_method_header
            if cur_tok.id? then
                name = cur_tok.value
                args = []
                step
            elsif cur_tok.binsel? then
                name = cur_tok.value
                step
                if !cur_tok.id? then
                    parse_error("Expected id")
                end
                args = [cur_tok.value]
                step
            elsif cur_tok.kw? then
                name = []
                args = []

                while cur_tok.kw? do
                    name << cur_tok.value.to_s
                    step
                    if !cur_tok.id? then
                        parse_error("Expected id")
                    end
                    args << AVar.new(cur_tok.value)
                    step
                end
                name = name.join.to_sym
            else
                parse_error("Expected id, binsel, or keyword")
            end

            return [name, args]
        end

        def parse_executable_code
            temps = parse_temps
            push_scope
            temps.each {|v| @scope.add_var(v)}
            stmts = parse_statements
            pop_scope
            [temps, stmts]
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
                if cur_tok.one_of [:caret, :int, :id, :lsq] then
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
            # FIXME: we sure check this a lot
            elsif cur_tok.one_of [:int, :id, :lsq] then
                parse_expr
            else
                parse_error
            end
        end

        def parse_return
            expect(:caret)
            ReturnNode.new(parse_expr)
        end

        def parse_expr
            if cur_tok.one_of [:int, :lsq] then
                parse_message
            elsif cur_tok.id? then
                parse_maybe_assign
            else
                parse_error
            end
        end

        def parse_maybe_assign
            tok = cur_tok
            step

            if cur_tok.assign? then
                step
                expr = parse_expr
                AssignNode.new(lookup_var(tok.value), expr)
            else
                push_token(tok)
                parse_message
            end
        end

        def parse_message
            r = parse_primary
            r = parse_unary(r)
            r = parse_binary(r)
            parse_keyword(r)
        end

        def parse_primary
            if cur_tok.int? then
                v = cur_tok.value
                step
                ConstNode.new(v)
            elsif cur_tok.id? then
                name = cur_tok.value
                step
                if [:true, :false, :nil].include? name then
                    ConstNode.new(const_value[name])
                else
                    RefNode.new(lookup_var(name))
                end
            elsif cur_tok.lsq? then
                parse_block
            else
                parse_error
            end
        end

        def const_value
            { :true => true, :false => false, :nil => nil }
        end

        def parse_block
            step
            args = []
            while cur_tok.blockarg? do
                args << cur_tok.value
                step
            end
            if args != [] then
                if cur_tok.value == :'|' then
                    step
                elsif cur_tok.value == :'||' then
                    step
                    push_token(Token.new(:binsel, :'|'))
                else
                    parse_error('Expected "|"')
                end
            end
            temps,stmts = parse_executable_code
            expect(:rsq)
            BlockNode.new(args, temps, stmts)
        end

        def parse_unary(r)
            while cur_tok.id? do
                r = MessageNode.new(r, cur_tok.value, [])
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
                r = MessageNode.new(r, op, [arg])
            end
            r
        end

        def parse_keyword(r)
            sel  = []
            args = []
            while cur_tok.kw? do
                sel << cur_tok.value.to_s
                step

                arg = parse_primary
                arg = parse_unary(arg)
                args <<  parse_binary(arg)
            end

            if sel != [] then
                r = MessageNode.new(r, sel.join.to_sym, args)
            end

            r
        end
    end
end

