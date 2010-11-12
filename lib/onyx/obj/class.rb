
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

        def oclass?
            true
        end

        def lookup_method(terp, selector, cls)
            if cls then
                d = cmdict
            else
                d = mdict
            end

            if d.include?(selector) then
                [self, d[selector]]
            elsif @super.nil? then
                if cls then
                    terp.globals[:Class].lookup_method(selector, false)
                else
                    nil
                end
            else
                @super.lookup_method(selector, cls)
            end
        end
    end
end

