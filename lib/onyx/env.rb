
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

        def assign(value)
            @value = value
        end
    end

    class IBinding
        include Binding
    end

    class Env
        attr_reader :parent

        def self.from_method(meth, args, rcvr, cls)
            env = self.new
            env.add_args(meth, args)
            env.add_temps(meth)
            env.add_binding(:self, rcvr)
            env.add_binding(:super, Super.new(cls, rcvr))
            env
        end

        def self.from_block(blk, args)
            env = self.new(blk.env)
            env.add_args(blk, args)
            env.add_temps(blk)
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

        def add_args(obj, vals)
            vals.each_index do |i|
                add_ibinding(obj.args[i], vals[i])
            end
        end

        def add_temps(obj)
            obj.temps.each do |t|
                add_binding(t)
            end
        end

        def add_binding(name, value=nil, bcls=MBinding)
            @binds[name] = bcls.new(name, value)
        end

        def add_ibinding(name, value)
            add_binding(name, value, IBinding)
        end
        
        def include?(var)
            if @binds.keys.include?(var) then
                true
            elsif @parent.nil? then
                false
            else
                @parent.include?(var)
            end
        end

        def inspect
            s = "<Env \n"
            @binds.each_value do |b|
                s = s + "  #{b.name} => #{b.value}\n"
            end

            s = s + ">\n"
            if @parent.nil? then
                s
            else
                s + @parent.inspect
            end
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
                v = add_binding(name)
            end
            v
        end

        def [](name)
            @binds[name].value
        end
    end
end

