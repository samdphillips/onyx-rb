
module Onyx
    class OClass
        attr_reader :name, :super, :ivars, :cvars, :mdict, :cmdict

        def initialize(name, super_cls, ivars, cvars, mdict, cmdict)
            @name   = name
            @super  = super_cls
            @ivars  = ivars
            @cvars  = cvars
            @mdict  = mdict
            @cmdict = cmdict
        end
    end
end

