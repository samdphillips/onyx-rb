
module Onyx
    class Env
        attr_reader :parent

        def initialize(parent=nil)
            @parent = parent
            @vars   = {}
        end

        def lookup_var(name)
            if @vars.include?(name) then
                @vars[name]
            else
                if @parent.nil?
                    nil
                else
                    @parent.lookup_var(name)
                end
            end
        end

        def add_var(var)
            @vars[var.name] = var
        end
        
        def include?(var)
            @vars.values.include?(var)
        end
    end

    class GScope < Env
        def lookup_var(name)
            v = super(name)

            if v.nil? then
                v = GVar.new(name)
                add_var(v)
            end
            v
        end
    end
end

