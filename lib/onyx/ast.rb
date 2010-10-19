
module Onyx
    class Var
        attr_reader :name

        def initialize(name)
            @name = name
        end
    end

    class GVar < Var
    end

    class IVar < Var
    end

    class TVar < Var
    end

    class Expr
        def block?
            false
        end
    end

    class ERef < Expr
        attr_reader :var

        def initialize(var)
            @var = var
        end
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

    class EBody < Expr
        attr_reader :temps, :stmts

        def initialize(temps, stmts)
            @temps = temps
            @stmts = stmts
        end
    end

    class EReturn < Expr
        attr_reader :expr

        def initialize(expr)
            @expr = expr
        end
    end

    class EBlock < Expr
        attr_reader :body

        def initialize(body)
            @body = body
        end

        def block?
            true
        end
    end

end
