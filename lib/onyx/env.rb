
module Onyx
    module Binding
        attr_reader :name, :value

        def initialize(name, value)
            @name = name
            @value = value
        end
    end

    class MBinding
        include Binding
    end

    class IBinding
        include Binding
    end

    class Env
        attr_reader :parent

        def initialize(parent=nil)
            @parent = parent
            @binds   = {}
        end

        def lookup(name)
            if @binds.include?(name) then
                @binds[name]
            else
                if @parent.nil?
                    nil
                else
                    @parent.lookup(name)
                end
            end
        end

        def add_binding(name, value=nil, bcls=MBinding)
            @binds[name] = bcls.new(name, value)
        end
        
        def include?(var)
            @binds.keys.include?(var)
        end
    end

    class GEnv < Env
        def initialize
            super
            add_binding(:nil, nil)
        end

        def lookup(name)
            v = super(name)

            if v.nil? then
                add_binding(name)
            end
            v
        end
    end
end

