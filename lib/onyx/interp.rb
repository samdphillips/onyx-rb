
module Onyx

    class TopReturnError < Exception
    end

    class Interpreter
        include Primitives
        include Frames

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
                @terp.continue(@value)
            end
        end

        def self.boot
            base = 'src/boot'
            sources = []
            sources << 'core'
            sources << 'exception'
            sources << 'number'
            sources << 'collection'
            sources << 'string'
            sources << 'stream'

            node = SeqNode.new
            sources.each do |src|
                node.nodes << Parser.parse_file("#{base}/#{src}.ost")
            end

            terp = self.new
            terp.eval(node)
            terp
        end

        attr_reader   :globals, :env, :rcvr, :retk, :state, :stack

        def initialize
            @globals = GEnv.new
            @env     = Env.new
            @stack   = Stack.new
            @retp    = nil
            @rcvr    = nil
            @state   = nil
            @marks   = {}
        end

        def pretty_print_instance_variables
            i = instance_variables
            i.delete("@globals")
            i.sort
        end

        def writeme
            raise 'writeme'
        end

        # Installs a Done state into @state.
        def done(value)
            @state = Done.new(self, value)
        end

        # Installs a Doing state into @state.
        def doing(node)
            @state = Doing.new(self, node)
        end

        def continue(value)
            frame = @stack.pop
            @env   = frame.env
            @rcvr  = frame.rcvr
            @retp  = frame.retk
            @marks = frame.marks
            frame.continue(value)
        end

        def reset
            @marks = {}
            @env   = Env.new
            @rcvr  = nil
        end

        def eval(node, stepping=false)
            self.doing(node)
            unless stepping then
                run

                # reset @env and @rcvr if we're returning to the top level
                if @stack.empty? and @state.done? then
                    reset
                end

                @state.value
            end
        end

        def eval_string(s, stepping=false)
            p = Parser.on_string(s)
            node = p.parse_module
            eval(node, stepping)
        end

        def eval_file(filename)
            p = Parser.parse_file(filename)
            eval(p)
        end

        def halted?
            @halt or (@stack.empty? and @state.done?)
        end

        def run
            @halt = false
            until halted? do
                step
            end
        end

        def step
            @state.step
        end

        def make_continuation(tag)
            prompt_frame = @stack.find_prompt(tag)
            frames = @stack.get_frames_after(prompt_frame)
            cont = @globals[:Continuation].new_instance
            cont.lookup(:frames).assign(frames)
            cont
        end

        def add_continuation(frames)
            frames.each do | frame |
                @stack.push(frame)
            end
        end

        def push_k(cls, *args)
            @stack.push(cls.new(self, @env, @rcvr, @retp, @marks, *args))
            @marks = {}
        end

        def push_kseq(nodes)
            push_k(SeqFrame, nodes)
        end

        def push_kassign(var)
            push_k(AssignFrame, var)
        end

        def push_krcvr(message)
            push_k(RcvrFrame, message)
        end

        def push_kcascade(rcvr, messages)
            push_k(CascadeFrame, rcvr, messages)
        end

        def push_kprompt(tag, abort_handler)
            push_k(PromptFrame, tag, abort_handler)
        end

        def push_ktrait(decl)
            push_k(TraitFrame, decl)
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
            name = cls_node.name
            push_kassign(name)
            super_cls = lookup_var(cls_node.supername).value
            mdict  = build_mdict(cls_node.meths)
            cmdict = build_mdict(cls_node.meta.meths)
            cls = OClass.new(name, super_cls, cls_node.ivars,
                             cls_node.meta.ivars, mdict, cmdict)
            if cls_node.trait_expr.nil? then
                done(cls)
            else
                push_ktrait(cls)
                doing(cls_node.trait_expr)
            end
        end

        def visit_trait(trait_node)
            name = trait_node.name
            push_kassign(name)
            mdict = build_mdict(trait_node.meths)
            cmdict = build_mdict(trait_node.meta.meths)
            trait = Trait.new(name, mdict, cmdict)
            if trait_node.trait_expr.nil? then
                done(trait)
            else
                push_ktrait(trait)
                doing(trait_node.trait_expr)
            end
        end

        def visit_const(const_node)
            c = const_node.value
            done(c)
        end

        def visit_block(block_node)
            blk = BlockClosure.new(@env, @rcvr, @retp, block_node)
            done(blk)
        end

        def visit_seq(seq_node)
            if seq_node.nodes.size == 0 then
                done(nil)
            elsif seq_node.nodes.size == 1 then
                doing(seq_node.nodes.first)
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
            if @retp.nil? then
                raise TopReturnError.new
            end
            @stack.top = @retp
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
            rcls = rcvr.onyx_class(self)
            if rcvr.class == Super then
                rcvr = rcvr.rcvr
            end
            cls, meth = rcls.lookup_method(self, selector, rcvr.onyx_class?)
            if cls.nil? then
                cls, meth = rcls.lookup_method(self, :'doesNotUnderstand:', rcvr.onyx_class?)
                if cls.nil? then
                    raise "DNU: #{rcvr} #{selector} [#{args.join(', ')}]"
                end

                args = make_dnu_args(selector, args)
            end

            @env  = Env.from_method(meth, args, rcvr, cls)
            @rcvr = rcvr
            @retp = @stack.top
            doing(meth.stmts)
        end

        def make_dnu_args(selector, args)
            msg = OObject.new(@globals.lookup(:Message).value, 2)
            msg.lookup(:selector).assign(selector)
            msg.lookup(:arguments).assign(args)
            [msg]
        end

        def do_block(blk, args=[])
            @env = Env.from_block(blk, args)
            @rcvr = blk.rcvr
            @retp = blk.retk
            doing(blk.stmts)
        end

        def do_primitive(selector, rcvr, args)
            send("prim#{selector.to_s.gsub(':','_')}".to_sym, rcvr, *args)
        end

        def do_trait_validation_error(missing)
            rcvr = RefNode.new(:IncompleteTrait)
            arg = ConstNode.new(missing)
            msg = MessageNode.new(:'missingSelectors:', [arg])
            send = SendNode.new(rcvr, msg)

            signal_msg = MessageNode.new(:signal, [])
            signal_send = SendNode.new(send, signal_msg)
            doing(signal_send)
        end
    end
end
