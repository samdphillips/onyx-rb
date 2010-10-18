
module Onyx
    class Compiler
        def initialize
            @ops = []
        end

        def compile(ast)
            ast.compile_with(self)
        end

        def compile_const(value)
            @ops << LDC.new(value)
        end

        def compile_add
            @ops << ADD
        end

        def compile_mul
            @ops << MUL
        end
    end
end

