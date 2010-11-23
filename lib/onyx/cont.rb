
module Onyx
    module Continuations
        class Cont
            attr_reader :terp, :parent, :env, :rcvr, :retk, :exc

            def initialize(terp, env, rcvr, retk, parent, exc, *kargs)
                @terp   = terp
                @parent = parent
                @env    = env
                @rcvr   = rcvr
                @retk   = retk
                @exc    = exc
                initialize_k(*kargs)
            end

            def initialize_k
            end

            def writeme
                raise "writeme"
            end

            def pretty_print_instance_variables
                [:@parent, :@env, :@rcvr, :@retk]
            end

            def kontinue(value)
                @terp.restore(self)
                continue(value)
            end
        end

        class KSeq < Cont
            def initialize_k(rest)
                @rest = rest
            end

            def pretty_print_instance_variables
                super + [:@rest]
            end

            def continue(value)
                if @rest.size == 1 then
                    @terp.doing(@rest[0])
                else
                    a = @rest.first
                    rest = @rest[1..-1]
                    @terp.push_kseq(rest)
                    @terp.doing(a)
                end
            end
        end

        class KAssign < Cont
            def initialize_k(var)
                @var = var
            end

            def pretty_print_instance_variables
                super + [:@var]
            end

            def continue(value)
                @terp.assign_var(@var, value)
            end
        end

        module ContMsg
            def visit_message(message, rcvr)
                if message.unary? then
                    @terp.do_send(message.selector, rcvr, [])
                else
                    continue_message(message, rcvr, KMsg)
                end
            end

            def visit_primmessage(message, rcvr)
                if message.unary? then
                    @terp.do_primitive(message.selector, rcvr, [])
                else
                    continue_message(message, rcvr, KPrim)
                end
            end

            def continue_message(message, rcvr, kcls)
                selector = message.selector
                args = message.args
                @terp.push_k(kcls, selector, rcvr, args[1..-1])
                @terp.doing(args.first)
            end
        end

        class KRcvr < Cont
            include ContMsg

            def initialize_k(message)
                @message = message
            end

            def pretty_print_instance_variables
                super + [:@message]
            end

            def continue(value)
                @message.visit(self, value)
            end

            def visit_cascade(message, value)
                a = message.messages.first
                rest = message.messages[1..-1]
                @terp.push_kcascade(value, rest)
                a.visit(self, value)
            end
        end

        class KCascade < Cont
            include ContMsg

            def initialize_k(rcvr_val, messages)
                @rcvr_val = rcvr_val
                @messages = messages
            end

            def pretty_print_instance_variables
                super + [:@rcvr_val, :@messages]
            end

            def continue(value)
                if @messages.size == 1 then
                    @messages.first.visit(self, @rcvr_val)
                else
                    a = @messages.first
                    rest = @messages[1..-1]
                    @terp.push_kcascade(@rcvr_val, rest)
                    a.visit(self, @rcvr_val)
                end
            end
        end

        class KMsg < Cont
            def initialize_k(selector, rcvr_v, args, vals=[])
                @selector = selector
                @rcvr_v   = rcvr_v
                @args     = args
                @vals     = vals
            end

            def pretty_print_instance_variables
                super + [:@selector, :@rcvr_v, :@args, :@vals]
            end

            def continue(value)
                vals = @vals + [ value ]
                if @args.size == 0 then
                    do_send(vals)
                else
                    a = @args[0]
                    args = @args[1..-1]
                    @terp.push_k(self.class, @selector, @rcvr_v, args, vals)
                    @terp.doing(a)
                end
            end

            def do_send(vals)
                @terp.do_send(@selector, @rcvr_v, vals)
            end
        end

        class KPrim < KMsg
            def do_send(vals)
                @terp.do_primitive(@selector, @rcvr_v, vals)
            end
        end

    end
end
