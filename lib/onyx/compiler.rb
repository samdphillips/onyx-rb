
module Onyx
    class Compiler
        SpecialMessage = {:+ => :compile_add,
                          :* => :compile_mul,
                          :'ifTrue:ifFalse:' => :compile_ifTrue_ifFalse}

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

        def compile_mul(ast)
            compile(ast.rcvr)
            compile_args(ast.args)
            @ops << MUL
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
    end
end

