
module Onyx
    class Interpreter
        include Primitives 
        include Continuations

        attr_reader :globals
        attr_accessor :cont

        def self.boot
            node = Parser.parse_file('system.ost')
            terp = self.new
            terp.eval(node)
            terp
        end

        def initialize
            @globals = GEnv.new
            @cont    = nil
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

        def visit_ref(ref_node)
            var = ref_node.var

            if @env.include?(var) then
                Done.new(@env.lookup(var).value)
            else
                raise 'need to write'
            end
        end

        def visit_send(send_node)
            @cont = KRcvr.new(@cont, send_node.message)
            Doing.new(send_node.rcvr)
        end

        def visit_return(ret_node)
            @cont = @cont.retk
            Doing.new(ret_node.expr)
        end

        def eval_message_with(rcvr, msg_node)
            args = msg_node.args.collect {|a| eval(a)}

            if msg_node.primitive? then
                m = :do_primitive
            else
                m = :do_send
            end
            send(m, rcvr, msg_node.selector, args)
        end

        def do_primitive(rcvr, sel, args)
            v = send("prim#{sel.to_s.gsub(':','_')}".to_sym, rcvr, *args)
            Done.new(v)
        end

        def do_send(k, rcvr, sel, args)
            cls = rcvr.onyx_class(self)
            cls, meth = cls.lookup_method(self, sel, rcvr.oclass?)
            if cls.nil? then
                raise "DNU: #{sel}"
            end
            @cont = KMethod.new(k, @env, @cls, @rcvr)
            @env  = Env.from_method(meth, args, rcvr, cls)
            @rcvr = rcvr
            @cls  = cls
            Doing.new(meth.stmts)
        end
    end
end

