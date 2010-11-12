
module Onyx
    class OObject
        def initialize(cls, size)
            @cls   = cls
            @slots = Array.new(size)
        end

        def onyx_class(terp)
            @cls
        end
    end
end
