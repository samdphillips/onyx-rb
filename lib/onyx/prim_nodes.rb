
module Onyx

    class BinopNode < ExprNode
        def self.expand(message)
            new(message.rcvr, message.args[0])
        end

        def initialize(rcvr, arg)
            rcvr.expand
            arg.expand
            @rcvr = rcvr
            @arg  = arg
        end

        def gen_value_code(cg)
            @rcvr.gen_value_code(cg)
            @arg.gen_value_code(cg)
            gen_op(cg)
        end
    end

    class AddNode < BinopNode
        def gen_op(cg)
            cg.prim_add
        end
    end

    class MulNode < BinopNode
        def gen_op(cg)
            cg.prim_mul
        end
    end

    MessageNode.register_special(:+, AddNode)
    MessageNode.register_special(:*, MulNode)

end
