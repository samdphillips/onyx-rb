
module Onyx
    class BlockClosure
        attr_reader :cls, :rcvr, :cont, :env, :args, :temps, :stmts

        def initialize(cls, rcvr, cont, env, node)
            @cls   = cls
            @rcvr  = rcvr
            @cont  = cont
            @env   = env
            @args  = node.args
            @temps = node.temps
            @stmts = node.stmts
        end

        def onyx_class(terp)
            terp.globals[:BlockClosure]
        end
    end
end

