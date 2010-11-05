
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

        def parse_import
            expect(:kw, :'import:')

            if cur_tok.string? then
                v = cur_tok.value.to_sym
                step
                if cur_tok.dot? then
                    step
                end
                ImportNode.new(v)
            else
                parse_error('Expected string')
            end
        end

        def parse_trait
            expect(:id, :Trait)
            expect(:kw, :'named:')
            name = cur_tok.value
            step
            parse_decl_body(TraitNode, name)
        end

        def parse_class
            supername = cur_tok.value
            step
            expect(:kw, :'subclass:')
            name = cur_tok.value
            step
            parse_decl_body(ClassNode, name, supername)
        end

        def parse_extension
            name = cur_tok.value
            step
            expect(:id, :extend)
            parse_decl_body(ClassExtNode, name)
        end

        def parse_meta
            expect(:lsq)
            vars = parse_vars
            meta_node = MetaNode.new(vars)

            while !cur_tok.rsq? do
                parse_meta_elem(meta_node)
            end

            expect(:rsq)
            meta_node
        end

        def parse_meta_elem(meta_node)
            if cur_tok.id? or cur_tok.binsel? or cur_tok.kw? then
                meta_node.add_method(parse_method)
            else
                parse_error('Expected id, binsel, or kw.')
            end
        end

        def parse_trait_clause
            t = parse_expr
            expect(:dot)
            t
        end

        def parse_decl_body(node_class, *inits)
            expect(:lsq)
            inits <<  parse_vars
            decl_node = node_class.new(*inits)

            while !cur_tok.rsq? do
                parse_decl_elem(decl_node)
            end

            expect(:rsq)
            decl_node
        end

        def parse_decl_elem(decl_node)
            if cur_tok.id? then
                tok = cur_tok
                step

                if cur_tok.lsq? then
                    push_token(tok) 
                    decl_node.add_method(parse_method)
                elsif cur_tok.kw? and cur_tok.value == :'uses:' then
                    if tok.value != decl_node.name then
                        parse_error("Trait clause name doesn't match")
                    end
                    step
                    decl_node.add_traits(parse_trait_clause)
                elsif cur_tok.id? and cur_tok.value == :class then
                    if tok.value != decl_node.name then
                        parse_error("Meta trait name doesn't match")
                    end
                    step
                    decl_node.add_meta(parse_meta)
                else
                    parse_error('Expected "[" or "uses:" or "class"')
                end
            elsif cur_tok.binsel? or cur_tok.kw? then
                decl_node.add_method(parse_method)
            else
                parse_error('Expected id, binsel, or kw.')
            end
        end

        def parse_method
            method = parse_method_header
            expect(:lsq)
            parse_executable_code(method)
            expect(:rsq)
            method
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
                    args << cur_tok.value
                    step
                end
                name = name.join.to_sym
            else
                parse_error("Expected id, binsel, or keyword")
            end

            MethodNode.new(name, args)
        end

        def parse_executable_code(node)
            node.add_temps(parse_vars)
            parse_statements(node)
        end

        def parse_vars
            vars = []

            if cur_tok.binsel? and cur_tok.value == :'|' then
                step

                while cur_tok.id? do
                    vars << cur_tok.value
                    step
                end

                expect(:binsel, :'|')
            elsif cur_tok.binsel? and cur_tok.value == :'||' then
                step
            end
            vars
        end

        def parse_statements(node)
            while true do
                if cur_tok.one_of [:caret, :int, :id, :lsq] then
                    node.stmts << parse_statement
                else
                    break
                end
                
                if cur_tok.dot? then
                    step
                else
                    break
                end
            end
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
                AssignNode.new(tok.value, expr)
            else
                push_token(tok)
                parse_message
            end
        end

        def parse_message
            r = parse_primary
            r = parse_unary(r)
            r = parse_binary(r)
            r = parse_keyword(r)

            if cur_tok.semi? then
                m = [r.message]
                r = r.rcvr
                while cur_tok.semi? do
                    step
                    m << parse_cascade_message
                end
                r = CascadeNode.new(r, m)
            end

            r
        end

        def parse_cascade_message
            if cur_tok.id? then
                parse_umsg
            elsif cur_tok.binsel? then
                parse_bmsg
            elsif cur_tok.kw? then
                parse_kmsg
            else
                parse_error("Expected id, binsel, kw.  Got #{cur_tok}")
            end
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
                    RefNode.new(name)
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
            if cur_tok.blockarg? then
                while cur_tok.blockarg? do
                    args << cur_tok.value
                    step
                end

                if cur_tok.value == :'|' then
                    step
                elsif cur_tok.value == :'||' then
                    step
                    push_token(Token.new(:binsel, :'|'))
                else
                    parse_error('Expected "|"')
                end
            end

            block = BlockNode.new(args)
            parse_executable_code(block)
            expect(:rsq)
            block
        end

        def new_message(selector, args=[])
            mklass = MessageNode
            if selector.to_s[0] == ?_ then
                mklass = PrimMessageNode
            end
            mklass.new(selector, args)
        end

        def parse_umsg
            sel = cur_tok.value
            step
            new_message(sel)
        end

        def parse_bmsg
            op = cur_tok.value
            step

            arg = parse_primary
            arg = parse_unary(arg)
            new_message(op, [arg])
        end

        def parse_kmsg
            sel  = []
            args = []

            while cur_tok.kw? do
                sel << cur_tok.value.to_s
                step

                arg = parse_primary
                arg = parse_unary(arg)
                args <<  parse_binary(arg)
            end

            sel = sel.join.to_sym
            new_message(sel, args)
        end

        def parse_unary(r)
            while cur_tok.id? do
                r = SendNode.new(r, parse_umsg)
            end
            r
        end

        def parse_binary(r)
            while cur_tok.binsel? do
                r = SendNode.new(r, parse_bmsg)
            end
            r
        end

        def parse_keyword(r)
            if cur_tok.kw? then
                r = SendNode.new(r, parse_kmsg)
            end

            r
        end
    end
end

