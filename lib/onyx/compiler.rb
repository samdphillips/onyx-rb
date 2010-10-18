
module Onyx
    class Compiler
        SpecialMessage = {:+ => :compile_add,
                          :* => :compile_mul}

        def initialize
            @ops = []
        end

        def compile(ast)
            ast.compile_with(self)
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
    end
end

