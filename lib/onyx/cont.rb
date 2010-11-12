
module Onyx
    module Continuations
        class Doing
            def initialize(node)
                @node = node
            end

            def step(terp)
                @node.visit(terp)
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
                inspect
            end
        end

        class Cont
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

        class KRcvr < Cont
            def initialize(parent, message)
                super(parent)
                @message = message
            end

            def continue(terp, value)
                @message.visit(self, terp, value)
            end

            def visit_message(msg_node, terp, value, kklass=KMsg)
                sel  = msg_node.selector
                args = msg_node.args
                if args.size == 0 then
                    kklass.new(@parent, sel, value).do_send(terp)
                else
                    terp.cont = kklass.new(@parent, sel, value, args[1..-1])
                    Doing.new(args[0])
                end
            end

            def visit_primmessage(msg_node, terp, value)
                visit_message(msg_node, terp, value, KPrim)
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
            def initialize(parent, env, cls, rcvr)
                super(parent)
                @env  = env
                @cls  = cls
                @rcvr = rcvr
            end

            def continue(terp, value)
                terp.cont = @parent
                Done.new(value)
            end

            def retk
                self
            end
        end
    end
end

    
