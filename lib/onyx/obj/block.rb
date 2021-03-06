
module Onyx
    class BlockClosure
        attr_reader :env, :rcvr, :args, :temps, :stmts
        attr_accessor :retk

        def initialize(env, rcvr, retk, node)
            @env   = env
            @rcvr  = rcvr
            @retk  = retk
            @args  = node.args
            @temps = node.temps
            @stmts = node.stmts
        end

        def onyx_class(terp)
            terp.globals[:BlockClosure]
        end
    end
end
