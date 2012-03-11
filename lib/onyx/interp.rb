
module Onyx
    class Interpreter
        include Primitives
        include Continuations

        class Doing
            def initialize(terp, node)
                @terp = terp
                @node = node
            end

            def pretty_print_instance_variables
                [:@node]
            end

            def done?
                false
            end

            def step
                @node.visit(@terp)
            end

            def to_s
                "<#{self.class.name} #{@node}>"
            end
        end

        class Done
            attr_reader :value

            def initialize(terp, value)
                @terp  = terp
                @value = value
            end

            def pretty_print_instance_variables
                [:@value]
            end

            def done?
                true
            end

            def step
                @terp.cont.kontinue(@value)
            end
        end

        def self.boot
            terp = self.new
            node = Parser.parse_file('system.ost')
            terp.eval(node)
            terp
        end

        attr_accessor :debug, :cont
        attr_reader   :globals, :env, :rcvr, :retk, :tramp

        def initialize
            @globals = GEnv.new
            @cont    = KHalt.new(self)
            @env     = Env.new
            @rcvr    = nil
            @retk    = nil
            @tramp   = nil
            @marks   = {}
            @debug   = false
        end

        def pretty_print_instance_variables
            i = instance_variables
            i.delete("@globals")
            i.sort
        end

        def writeme
            raise 'writeme'
        end

        # Installs a Done state into @tramp.
        def done(value)
            @tramp = Done.new(self, value)
        end

        # Installs a Doing state into @tramp.
        def doing(node)
            @tramp = Doing.new(self, node)
        end

        def restore(k)
            @cont  = k.parent
            @env   = k.env
            @rcvr  = k.rcvr
            @retk  = k.retk
            @marks = k.marks
        end

        def eval(node, stepping=false)
            self.doing(node)
            unless stepping then
                run

                # reset @env and @rcvr if we're returning to the top level
                if @cont.halt? and @tramp.done? then
                    @marks = {}
                    @env   = Env.new
                    @rcvr  = nil
                end

                @tramp.value
            end
        end

        def eval_string(s, stepping=false)
            p = Parser.on_string(s)
            node = p.parse_module
            eval(node, stepping)
        end

        def halted?
            @halt or (@cont.halt? and @tramp.done?)
        end

        def run
            @halt = false
            pp(self) if @debug
            until halted? do
                step
                puts     if @debug
                pp(self) if @debug
            end
        end

        def step
            @tramp.step
        end

        def push_k(cls, *args)
            @cont = cls.new(self, @env, @rcvr, @retk, @cont, @marks, *args)
        end

        def push_kseq(nodes)
            push_k(KSeq, nodes)
        end

        def push_kassign(var)
            push_k(KAssign, var)
        end

        def push_krcvr(message)
            push_k(KRcvr, message)
        end

        def push_kcascade(rcvr, messages)
            push_k(KCascade, rcvr, messages)
        end

        def push_kprompt(tag)
            push_k(KPrompt, tag)
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
            done(nil)
        end

        def visit_const(const_node)
            c = const_node.value
            done(c)
        end

        def visit_block(block_node)
            blk = BlockClosure.new(@env, @rcvr, @retk, block_node)
            done(blk)
        end

        def visit_seq(seq_node)
            if seq_node.nodes.size == 1 then
                doing(seq_node.nodes[0])
            else
                a = seq_node.nodes.first
                rest = seq_node.nodes[1..-1]
                push_kseq(rest)
                doing(a)
            end
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

        def assign_var(var, value)
            lookup_var(var).assign(value)
        end

        def visit_ref(ref_node)
            done(lookup_var(ref_node.var).value)
        end

        def visit_assign(assign_node)
            var  = assign_node.var
            expr = assign_node.expr
            push_kassign(var)
            doing(expr)
        end

        def visit_return(ret_node)
            @cont = @retk
            doing(ret_node.expr)
        end

        def visit_send(send_node)
            push_krcvr(send_node.message)
            doing(send_node.rcvr)
        end

        def visit_cascade(casc_node)
            push_krcvr(casc_node)
            doing(casc_node.rcvr)
        end

        def do_send(selector, rcvr, args)
            cls = rcvr.onyx_class(self)
            if rcvr.class == Super then
                rcvr = rcvr.rcvr
            end
            cls, meth = cls.lookup_method(self, selector, rcvr.oclass?)
            if cls.nil? then
                raise "DNU: #{rcvr} #{selector} [#{args.join(', ')}]"
            end

            if @debug then
                puts
                puts "SEND #{selector}" if @debug
            end
            
            @env  = Env.from_method(meth, args, rcvr, cls)
            @rcvr = rcvr
            @retk = @cont
            doing(meth.stmts)
        end

        def do_block(blk, args=[])
            @env = Env.from_block(blk, args)
            @rcvr = blk.rcvr
            @retk = blk.retk
            doing(blk.stmts)
        end

        def do_primitive(selector, rcvr, args)
            send("prim#{selector.to_s.gsub(':','_')}".to_sym, rcvr, *args)
        end
    end
end

