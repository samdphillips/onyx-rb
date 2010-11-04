
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
        def block?
            false
        end

        def compile
            expand
            cg = CodeGen.new
            gen_value_code(cg)
            cg
        end

        def gen_effect_code(cg)
            gen_value_code(cg)
            cg.pop
        end
    end

    class SeqNode < ExprNode
        attr_reader :exprs

        def initialize(exprs)
            @exprs = exprs
        end

        def expand
            @exprs.each {|e| e.expand}
        end

        def gen_value_code(cg)
            (0...@exprs.size - 1).each do |i|
                @exprs[i].gen_effect_code(cg)
            end

            @exprs.last.gen_value_code(cg)
        end
    end

    class RefNode < ExprNode
        attr_reader :var

        def initialize(var)
            @var = var
        end

        def expand
        end
    end

    class ConstNode < ExprNode
        attr_reader :value

        def initialize(value)
            @value = value
        end

        def expand
        end

        def gen_value_code(cg)
            cg.push_const(@value)
        end
    end

    class MessageNode < ExprNode
        attr_reader :rcvr, :msg, :args

        SpecialMessage = {}

        def self.register_special(message, klass)
            SpecialMessage[message] = klass
        end

        def initialize(rcvr, msg, args)
            @rcvr     = rcvr
            @msg      = msg
            @args     = args
            @expanded = nil
        end

        def expand
            if SpecialMessage.include?(@msg) then
                @expanded = SpecialMessage[@msg].expand(self)
            end

            if @expanded.nil? then
                @rcvr.expand
                @args.each {|a| a.expand}
            end
        end

        def gen_value_code(cg)
            if @expanded.nil? then
                # normal send
                gotta_write
            else
                @expanded.gen_value_code(cg)
            end
        end
    end

    class ReturnNode < ExprNode
        attr_reader :expr

        def initialize(expr)
            @expr = expr
        end

        def expand
            @expr.expand
        end
    end

    class BlockNode < ExprNode
        attr_reader :args, :temps, :stmts, :free

        def initialize(args, temps, stmts)
            @args = args
            @temps = temps
            @stmts = stmts
            @free  = []
        end

        def block?
            true
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

        def compile
            @stmts.expand
            cg = CodeGen.new
            @stmts.gen_value_code(cg)
            cg
        end
    end
end
