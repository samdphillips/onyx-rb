
module Onyx
    class Compiler
        def initialize
        end

        def compile(ast)
            @ops = []
            ast.compile_with(self)
            @ops
        end

        def compile_const(value)
            @ops << LDC.new(value)
        end
    end
end

