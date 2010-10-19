
module Onyx
    class Compiler
        SpecialMessage = {:+   => :compile_add,
                          :'-' => :compile_sub,
                          :*   => :compile_mul,
                          :'=' => :compile_equal,
                          :'ifTrue:ifFalse:' => :compile_ifTrue_ifFalse,
                          :'whileFalse:' => :compile_whileFalse}

        def initialize
            @ops = []
            @label_count = 0
        end

        def new_label(tag='L')
            @label_count = @label_count + 1
            Label.new("#{tag}#{@label_count}")
        end

        def compile(ast)
            ast.compile_with(self)
        end

        def compile_seq(ast)
            ast.each {|t| compile(t)}
        end

        def compile_const(ast)
            @ops << LDC.new(ast.value)
        end

        def compile_method(m)
            @ops = []
            @args = m.args
            @temps = m.temps
            @ops << TEMPS.new(@temps.size)
            compile_seq(m.body)
            @ops
        end

        def compile_temp_ref(var)
            @ops << LDT.new(@temps.index(var))
        end

        def compile_temp_assign(var, expr)
            compile(expr)
            @ops << STT.new(@temps.index(var))
        end

        def compile_return(r)
            compile(r.expr)
            @ops << RET
        end

        def compile_send(ast)
            if SpecialMessage.include?(ast.msg) then
                send(SpecialMessage[ast.msg], ast)
            else
                compile_normal_send(ast)
            end
        end

        def compile_normal_send(ast)
            label = new_label('frame')
            compile(ast.rcvr)
            compile_args(ast.args)
            puts ast.inspect
            need_to_write
            @ops << label
        end

        def compile_args(args)
            args.each {|a| compile(a) }
        end

        def compile_add(ast)
            compile(ast.rcvr)
            compile_args(ast.args)
            @ops << ADD
        end

        def compile_sub(ast)
            compile(ast.rcvr)
            compile_args(ast.args)
            @ops << SUB
        end

        def compile_mul(ast)
            compile(ast.rcvr)
            compile_args(ast.args)
            @ops << MUL
        end

        def compile_equal(ast)
            compile(ast.rcvr)
            compile_args(ast.args)
            @ops << EQ
        end

        def compile_ifTrue_ifFalse(ast)
            tcode = ast.args[0]
            fcode = ast.args[1]
            test  = ast.rcvr

            if tcode.block? and fcode.block? then
                # TODO: error if block vars
                # TODO: block temps need to migrate to method temps
                l1 = new_label('false')
                l2 = new_label('end')
                compile(test)
                @ops << JMPF.new(l1)
                compile_seq(tcode.body.stmts)
                @ops << JMP.new(l2)
                @ops << l1
                compile_seq(fcode.body.stmts)
                @ops << l2
            else
                compile_normal_send(ast)
            end
        end

        def compile_whileFalse(ast)
            test = ast.rcvr
            body = ast.args[0]

            if test.block? and body.block? then
                l_start = new_label('loop-start')
                l_end = new_label('loop-end')
                @ops << l_start
                compile_seq(test.body.stmts)
                @ops << JMPF.new(l_end)
                compile_seq(body.body.stmts)
                @ops << JMP.new(l_start)
                @ops << l_end
            else
                compile_normal_send(ast)
            end
        end
    end
end

