
module Onyx
    class Interpreter
        include Primitives 
        include Continuations

        attr_reader :globals
        attr_accessor :cont, :debug

        def self.boot
            node = Parser.parse_file('system.ost')
            terp = self.new
            terp.eval(node)
            terp
        end

        def initialize
            @globals = GEnv.new
            @cont    = nil
            @env     = Env.new
            @debug   = false
        end

        def restore(env, cls, rcvr)
            @env = env
            @cls = cls
            @rcvr = rcvr
        end

        def eval_string(s)
            p = Parser.on_string(s)
            node = p.parse_module
            eval(node)
        end

        def eval(node)
            @state = Doing.new(node)
            run
        end

        def finished?
            @cont.nil? and @state.class == Done
        end

        def run
            until finished? do
                @state = @state.step(self)
                puts "state: #{@state}" if @debug
                puts "cont:  #{@cont.inspect}" if @debug
                puts if @debug
            end
            @state.value
        end

        def visit_seq(seq)
            a = seq.nodes.first
            rest = seq.nodes[1..-1]
            @cont = KSeq.new(@cont, rest)
            Doing.new(a)
        end

        def build_mdict(meths)
            mdict = {}
            meths.each do | m |
                mdict[m.name] = 
                    OMethod.new(m.name, m.args, m.temps, m.stmts)
            end
            mdict
        end

        def visit_class(cls_node)
            super_cls = @globals.lookup(cls_node.supername).value
            name = cls_node.name
            mdict  = build_mdict(cls_node.meths)
            cmdict = build_mdict(cls_node.meta.meths)
            cls = OClass.new(name, super_cls, cls_node.ivars,
                cls_node.meta.ivars, mdict, cmdict)
            @globals.add_binding(name, cls)
            Done.new(nil)
        end

        def visit_const(const_node)
            Done.new(const_node.value)
        end

        def lookup_var(var)
            if @env.include?(var) then
                @env.lookup(var)
            elsif @rcvr.include_ivar?(var) then
                @rcvr.lookup(var)
            else
                @globals.lookup(var)
            end
        end

        def visit_ref(ref_node)
            Done.new(lookup_var(ref_node.var).value)
        end

        def assign_var(var, value)
            lookup_var(var).assign(value)
        end

        def visit_assign(assign_node)
            var = assign_node.var
            expr = assign_node.expr

            @cont = KAssign.new(@cont, var)
            Doing.new(expr)
        end

        def visit_block(block_node)
            blk = BlockClosure.new(@cls, @rcvr, @cont, @env, block_node)
            Done.new(blk)
        end

        def visit_send(send_node)
            @cont = KRcvr.new(@cont, send_node.message)
            Doing.new(send_node.rcvr)
        end

        def visit_cascade(cascade_node)
            @cont = KRcvr.new(@cont, cascade_node)
            Doing.new(cascade_node.rcvr)
        end

        def visit_return(ret_node)
            @cont = @cont.retk
            @cont.context_return!
            Doing.new(ret_node.expr)
        end

        def do_primitive(rcvr, sel, args)
            puts "primitive: #{sel}" if @debug
            v = send("prim#{sel.to_s.gsub(':','_')}".to_sym, rcvr, *args)
            v
        end

        def prim_success(v)
            Done.new(v)
        end

        def do_send(k, rcvr, sel, args)
            cls = rcvr.onyx_class(self)
            cls, meth = cls.lookup_method(self, sel, rcvr.oclass?)
            if cls.nil? then
                raise "DNU: #{sel}"
            end
            puts "send: #{sel}" if @debug
            @cont = KMethod.new(k, @env, @cls, @rcvr, rcvr)
            @env  = Env.from_method(meth, args, rcvr, cls)
            @rcvr = rcvr
            @cls  = cls
            Doing.new(meth.stmts)
        end

        def do_block(blk, args=[])
            @cont = KBlock.new(@cont, @env, @cls, @rcvr, blk.cont)
            @env  = Env.from_block(blk, args)
            @rcvr = blk.rcvr
            @cls  = blk.cls
            Doing.new(blk.stmts)
        end
    end
end

