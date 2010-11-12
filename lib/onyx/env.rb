
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

        def self.from_method(meth, args, rcvr, cls)
            env = Env.new

            args.each_index do |i|
                env.add_ibinding(meth.args[i], args[i])
            end

            meth.temps.each do |t|
                env.add_binding(t)
            end

            env.add_binding(:self, rcvr)
            env.add_binding(:super, Super.new(cls, rcvr))

            env
        end

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

        def add_ibinding(name, value)
            add_binding(name, value, IBinding)
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

        def [](name)
            @binds[name].value
        end
    end
end

