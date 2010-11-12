
module Onyx
    module Continuations
        class Doing
            def initialize(node)
                @node = node
            end

            def step(terp)
                @node.visit(terp)
            end

            def to_s
                "<Doing #{@node}>"
            end
        end

        class Done
            attr_reader :value

            def initialize(value)
                @value = value
            end

            def step(terp)
                if terp.cont.nil? then
                    terp.running = false
                    self
                else
                    terp.cont.continue(terp, @value)
                end
            end

            def to_s
                "<Done #{@value}>"
            end
        end

        class Cont
            attr_reader :parent

            def initialize(parent)
                @parent = parent
            end

            def retk
                if @parent.nil? then
                    nil
                else
                    @parent.retk
                end
            end

            def chain
                k = self
                c = []
                until k.nil? do
                    c = c + [ k.to_s ]
                    k = k.parent
                end
                c
            end
            
            def inspect
                chain.join(" <- ")
            end
        end

        class KSeq < Cont
            def initialize(parent, nodes)
                super(parent)
                @nodes  = nodes
            end

            def continue(terp, value)
                if @nodes == [] then
                    terp.cont = @parent
                    Done.new(value)
                else
                    node = @nodes[0]
                    nodes = @nodes[1..-1]
                    terp.cont = KSeq.new(@parent, nodes)
                    Doing.new(node)
                end
            end
        end

        class KAssign < Cont
            def initialize(parent, var)
                super(parent)
                @var = var
            end

            def continue(terp, value)
                terp.assign_var(@var, value)
                terp.cont = @parent
                Done.new(value)
            end
        end

        class KArg < Cont
            def visit_message(msg_node, terp, value, k, kklass=KMsg)
                sel  = msg_node.selector
                args = msg_node.args
                if args.size == 0 then
                    kklass.new(k, sel, value).do_send(terp)
                else
                    terp.cont = kklass.new(k, sel, value, args[1..-1])
                    Doing.new(args[0])
                end
            end

            def visit_primmessage(msg_node, terp, value, k)
                visit_message(msg_node, terp, value, k, KPrim)
            end
        end

        class KRcvr < KArg
            def initialize(parent, message)
                super(parent)
                @message = message
            end

            def continue(terp, value)
                @message.visit(self, terp, value, @parent)
            end

            def visit_cascade(casc_node, terp, value, k)
                k = KCascade.new(@parent, value, casc_node.messages[1..-1])
                casc_node.messages[0].visit(self, terp, value, k)
            end

        end

        class KCascade < KArg
            def initialize(parent, rcvr, messages)
                super(parent)
                @rcvr     = rcvr
                @messages = messages
            end

            def continue(terp, value)
                if @messages.size == 1 then
                    m = @messages[0]
                    m.visit(self, terp, @rcvr, @parent)
                else
                    raise "writeme2"
                end
            end
        end

        class KMsg < Cont
            def initialize(parent, sel, rcvr, args=[])
                super(parent)
                @sel  = sel
                @rcvr = rcvr
                @args = args
                @vals = []
            end

            def continue(terp, value)
                @vals << value

                if @args.size == 0 then
                    do_send(terp)
                else
                    a = @args.shift
                    Doing.new(a)
                end
            end

            def do_send(terp)
                terp.do_send(@parent, @rcvr, @sel, @vals)
            end
        end

        class KPrim < KMsg
            def do_send(terp)
                terp.cont = @parent
                terp.do_primitive(@rcvr, @sel, @vals)
            end
        end

        class KMethod < Cont
            def initialize(parent, env, cls, old_rcvr, rcvr)
                super(parent)
                @env         = env
                @cls         = cls
                @old_rcvr    = old_rcvr
                @rcvr        = rcvr
                @return_self = true
            end

            def context_return!
                @return_self = false
            end

            def continue(terp, value)
                terp.cont = @parent
                terp.restore(@env, @cls, @old_rcvr)
                v = value
                if @return_self then
                    v = @rcvr
                end

                Done.new(v)
            end

            def retk
                self
            end
        end

        class KBlock < Cont
            def initialize(parent, env, cls, rcvr, cont)
                super(parent)
                @env  = env
                @cls  = cls
                @rcvr = rcvr
                @cont = cont
                @normal_return = true
            end

            def continue(terp, value)
                if @normal_return then
                    terp.cont = @parent
                    terp.restore(@env, @cls, @rcvr)
                else
                    raise "writeme"
                end
                Done.new(value)
            end

            def retk
                self
            end
        end
    end
end

    
