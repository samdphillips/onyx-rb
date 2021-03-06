
require 'stringio'

module Onyx
    class ParseError < Exception
        def initialize(parser, message='')
            @parser = parser
            @message = message
        end

        def message
            "#{@message}, at \"#{@parser.cur_tok.value}\" (#{@parser.cur_tok.type})"
        end
    end

    class Parser
        def self.parse_file(file_name)
            f = File.open(file_name)
            begin
                p = new(f)
                node = p.parse_module
            ensure
                f.close
            end
        end

        def self.on_string(s)
            new(StringIO.new(s))
        end

        def initialize(io)
            @lex = Lexer.new(io)
            @stack = []
            step
        end

        def push_token(tok)
            @stack << tok
        end

        def step
            if @stack.empty? then
                @cur_tok = @lex.next
            else
                @stack.shift
            end
        end

        def cur_tok
            if @stack.empty? then
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

        def parse_module
            e = []

            while !cur_tok.eof? do
                e << parse_module_elem
            end

            SeqNode.new(e)
        end

        def parse_module_elem
            if cur_tok.kw? and cur_tok.value == :'import:' then
                parse_import
            elsif cur_tok.id? and cur_tok.value == :Trait then
                parse_trait
            elsif cur_tok.id? then
                id = cur_tok
                step
                if cur_tok.kw? and cur_tok.value == :'subclass:' then
                    push_token(id)
                    parse_class
                else
                    push_token(id)
                    parse_module_expr
                end
            else
                parse_module_expr
            end
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
                    decl_node.add_trait_expr(parse_trait_clause)
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
            seq = SeqNode.new
            while true do
                if cur_tok.one_of [:caret, :int, :string, :symbol, :id, :lpar, :lcurl, :lparray, :lsq] then
                    seq.nodes << parse_statement
                else
                    node.stmts = seq
                    break
                end
                
                if cur_tok.dot? then
                    step
                else
                    node.stmts = seq
                    break
                end
            end
        end

        def parse_statement
            if cur_tok.caret? then
                parse_return
            # FIXME: we sure check this a lot
            elsif cur_tok.one_of [:string, :int, :symbol, :id, :lpar, :lcurl, :lparray, :lsq] then
                parse_expr
            else
                parse_error
            end
        end

        def parse_return
            expect(:caret)
            ReturnNode.new(parse_expr)
        end

        def parse_module_expr
            e = parse_expr
            unless cur_tok.eof? then
                expect(:dot)
            end
            e
        end

        def parse_expr
            if cur_tok.one_of [:lcurl, :lpar, :lparray, :string, :int, :symbol, :character, :lsq] then
                parse_message
            elsif cur_tok.id? then
                parse_maybe_assign
            else
                parse_error
            end
        end

        def parse_nested_expr
            step
            e = parse_expr
            expect(:rpar)
            e
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
            if cur_tok.one_of [:string, :int, :symbol] then
                v = cur_tok.value
                step
                ConstNode.new(v)
            elsif cur_tok.character? then
                v = Char.code_point(cur_tok.value.codepoints[0])
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
            elsif cur_tok.lpar? then
                parse_nested_expr
            elsif cur_tok.lparray? then
                parse_literal_array
            elsif cur_tok.lsq? then
                parse_block
            elsif cur_tok.lcurl? then
                parse_expr_array
            else
                parse_error
            end
        end

        def const_value
            { :true => true, :false => false, :nil => nil }
        end

        def parse_literal_array
            expect(:lparray)
            arr = []
            while cur_tok.one_of([:id, :string, :int, :symbol, :character]) do
                v = cur_tok.value

                if cur_tok.type == :character then
                    v = Char.code_point(v.codepoints[0])
                end

                arr << v
                step
            end
            expect(:rpar)
            ConstNode.new(arr)
        end

        def parse_expr_array
            expect(:lcurl)
            a = ExprArrayNode.new
            parse_statements(a)
            expect(:rcurl)
            a.expand
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

