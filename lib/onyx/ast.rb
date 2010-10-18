
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

        def compile_with(c)
            c.compile_const(self)
        end
    end

    class ESend < Expr
        attr_reader :rcvr, :msg, :args

        def initialize(rcvr, msg, args)
            @rcvr = rcvr
            @msg  = msg
            @args = args
        end

        def compile_with(c)
            c.compile_send(self)
        end
    end
end
