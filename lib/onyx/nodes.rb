
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
    end

    class ParseNode
    end

    class ExprNode < ParseNode
    end

    class SeqNode < ExprNode
        attr_reader :exprs

        def initialize(exprs)
            @exprs = exprs
        end
    end

    class RefNode < ExprNode
        attr_reader :var

        def initialize(var)
            @var = var
        end
    end

    class ConstNode < ExprNode
        attr_reader :value

        def initialize(value)
            @value = value
        end
    end

    class MessageNode < ExprNode
        attr_reader :rcvr, :msg, :args

        def initialize(rcvr, msg, args)
            @rcvr     = rcvr
            @msg      = msg
            @args     = args
        end
    end

    class ReturnNode < ExprNode
        attr_reader :expr

        def initialize(expr)
            @expr = expr
        end
    end

    class BlockNode < ExprNode
        attr_reader :args, :temps, :stmts

        def initialize(args, temps, stmts)
            @args = args
            @temps = temps
            @stmts = stmts
        end
    end
    
    class AssignNode < ExprNode
        attr_reader :var, :expr

        def initialize(var, expr)
            @var = var
            @expr = expr
        end
    end

    class MethodNode < ParseNode
        attr_reader :name, :args, :temps, :stmts

        def initialize(name, args, temps, stmts)
            @name = name
            @args = args
            @temps = temps
            @stmts = stmts
        end
    end
end
