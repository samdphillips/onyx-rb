
module Onyx
    class Super
        attr_reader :cls, :rcvr

        def initialize(cls, rcvr)
            @cls  = cls
            @rcvr = rcvr
        end

        def onyx_class(terp)
            @cls.super
        end

        def inspect
            to_s
        end
    end
end

