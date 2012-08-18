
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

        def pretty_print_instance_variables
            ["@name", "@super"]
        end

        def onyx_class?
            true
        end

        def onyx_class(terp)
            self
        end

        def new_instance
            OObject.new(self, all_ivars.size)
        end

        def all_ivars
            if @all_ivars.nil? then
                if @super.nil? then
                    @all_ivars = @ivars
                else
                    @all_ivars = @super.all_ivars + @ivars
                end
            end
            @all_ivars
        end

        def ivar_index(var)
            all_ivars.index(var)
        end
    end
end

