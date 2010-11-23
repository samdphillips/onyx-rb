
module Onyx
    class OObject
        class Slot
            attr_reader :value

            def assign(value)
                @value = value
            end
        end

        def initialize(cls, size)
            @cls   = cls
            @slots = []
            size.times do |i|
                @slots << Slot.new
            end
        end

        def onyx_class(terp=nil)
            @cls
        end
        
        def include_ivar?(var)
            @cls.all_ivars.include?(var)
        end

        def lookup(var)
            i = @cls.ivar_index(var)
            @slots[i]
        end
    end
end
