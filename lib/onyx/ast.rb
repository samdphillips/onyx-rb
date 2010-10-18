
module Onyx
    class Expr
    end

    class EConst < Expr
        attr_reader :value

        def initialize(value)
            @value = value
        end

        def ==(other)
            self.class == other.class and 
                @value == other.value
        end

        def compile_with(compiler)
            compiler.compile_const(value)
        end
    end
end
