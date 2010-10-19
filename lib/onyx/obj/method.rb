
module Onyx
    class OMethod
        attr_reader :code, :lits

        def initialize(code, lits)
            @code = code
            @lits = lits
        end

        def ==(other)
            self.class == other.class and
                code == other.code and
                lits == other.lits
        end
    end
end

