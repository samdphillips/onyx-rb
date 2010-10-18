
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
            c.compile_const(value)
        end
    end

    class ESend < Expr
        Specials = {:+ => :compile_add,
                    :* => :compile_mul}

        def initialize(rcvr, msg, args)
            @rcvr = rcvr
            @msg  = msg
            @args = args
        end

        def compile_with(c)
            @args.reverse.each do | a |
                c.compile(a)
            end
            c.compile(@rcvr)

            if Specials.include?(@msg) then
                send(Specials[@msg], c)
            else
                need_to_write
            end
        end

        def compile_add(c)
            c.compile_add
        end

        def compile_mul(c)
            c.compile_mul
        end
    end
end
