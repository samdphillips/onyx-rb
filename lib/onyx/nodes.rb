
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

    class CascadeNode < ExprNode
        attr_reader :rcvr, :messages

        def initialize(rcvr, messages)
            @rcvr     = rcvr
            @messages = messages
        end
    end

    class SendNode < ExprNode
        attr_reader :rcvr, :message

        def initialize(rcvr, message)
            @rcvr    = rcvr
            @message = message
        end
    end

    class MessageNode < ParseNode
        attr_reader :selector, :args

        def initialize(selector, args)
            @selector = selector
            @args     = args
        end
    end

    class PrimMessageNode < MessageNode
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

    class DeclNode < ParseNode
        attr_reader :name, :ivars, :trait_expr, :meta, :methods

        def initialize(name, ivars)
            @name       = name
            @ivars      = ivars
            @trait_expr = nil
            @meta       = []
            @methods    = []
        end

        def add_traits(trait_expr)
            @trait_expr = trait_expr
        end

        def add_meta(meta_node)
            @meta << meta_node
        end

        def add_method(method_node)
            @methods << method_node
        end
    end

    class ClassNode < DeclNode
        attr_reader :supername

        def initialize(name, supername, ivars)
            super(name, ivars)
            @supername = supername
        end
    end

    class TraitNode < DeclNode
    end

    class MetaNode < ParseNode
        attr_reader :ivars, :methods

        def initialize(ivars)
            @ivars   = ivars
            @methods = []
        end

        def add_method(method_node)
            @methods << method_node
        end
    end
end
