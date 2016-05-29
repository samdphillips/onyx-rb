
module Onyx
    class OClass
        attr_reader :name, :super, :ivars, :cvars, :trait, :mdict, :cmdict

        def initialize(name, super_cls, ivars, cvars, mdict, cmdict)
            @name   = name
            @super  = super_cls
            @ivars  = ivars
            @cvars  = cvars
            @trait  = trait
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

        def add_trait(trait)
            @trait = trait
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

        def instance_lookup_method(terp, selector)
            if mdict.include? selector then
                [self, mdict[selector]]
            elsif not @trait.nil? and @trait.include? selector then
                [self, @trait[selector]]
            elsif @super.nil? then
                nil
            else
                @super.instance_lookup_method(terp, selector)
            end
        end

        def class_lookup_method(terp, selector)
            if cmdict.include? selector then
                [self, cmdict[selector]]
            elsif not @trait.nil? and @trait.cls.include? selector then
                [self, @trait.cls[selector]]
            elsif @super.nil? then
                terp.globals[:Class].instance_lookup_method(terp, selector)
            else
                @super.class_lookup_method(terp, selector)
            end
        end

        def lookup_method(terp, selector, cls)
            if cls then
                class_lookup_method(terp, selector)
            else
                instance_lookup_method(terp, selector)
            end
        end
    end
end

