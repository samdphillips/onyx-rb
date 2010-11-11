
module Onyx
    class OMethod
        attr_reader :name, :args, :temps, :stmts

        def initialize(name, args, temps, stmts)
            @name  = name
            @args  = args
            @temps = temps
            @stmts = stmts
        end
    end
end

