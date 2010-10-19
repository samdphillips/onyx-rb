
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

    class AVar < Var
    end

    class TVar < Var
        def compile_ref_with(c)
            c.compile_temp_ref(self)
        end

        def compile_assign_with(c, expr)
            c.compile_temp_assign(self, expr)
        end
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

        def compile_with(c)
            @var.compile_ref_with(c)
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

        def compile_with(c)
            c.compile_return(self)
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
    
    class EAssign < Expr
        def initialize(var, expr)
            @var = var
            @expr = expr
        end

        def compile_with(c)
            @var.compile_assign_with(c, @expr)
        end
    end

    class EMethod < Expr
        attr_reader :args

        def initialize(name, args, body)
            @name = name
            @args = args
            @body = body
        end

        def temps
            @body.temps
        end

        def body
            @body.stmts
        end

        def compile_with(c)
            c.compile_method(self)
        end
    end
end
