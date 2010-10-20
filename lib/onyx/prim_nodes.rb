
module Onyx

    class AddNode < ExprNode
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
            cg.prim_add
        end
    end

    MessageNode.register_special(:+, AddNode)

end
