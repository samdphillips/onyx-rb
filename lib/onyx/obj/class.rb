
module Onyx
    class OClass
        attr_reader :name, :super

        def initialize(name, superclass)
            @name = name
            @super = superclass
        end
    end
end

