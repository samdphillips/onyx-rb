
module Onyx
    class Stack
        attr_accessor :top

        def initialize
            @frames = []
            @top = -1
        end

        def halt?
            @top == -1
        end

        def full?
            @top + 1 == @frames.size
        end

        def grow_stack
            @frames = @frames + Array.new(16)
        end

        def push(frame)
            if full? then
                grow_stack
            end

            @top += 1
            @frames[@top] = frame
        end

        def pop
            @top -= 1
        end

        def continue(value)
            @frames[@top].kontinue(value)
        end
    end

    module Frames

        # Common functionality shared by all frames.
        # @abstract 
        class Frame
            attr_reader :terp, :parent, :env, :rcvr, :retk, :marks

            # @param [Interpreter] terp
            # @param [Env] env Saved environment
            # @param [Object] rcvr Saved receiver object
            # @param [Continuation] retk Saved return Continuation
            # @param [Continuation] parent The previous Continuation
            # @param [Hash<Object,Object>] marks - Continuation marks on this frame
            # @param [Array<Object>] *kargs - Continuation specific arguments
            def initialize(terp, env, rcvr, retk, parent, marks, *kargs)
                @terp   = terp
                @parent = parent
                @env    = env
                @rcvr   = rcvr
                @retk   = retk
                @marks  = marks
                initialize_k(*kargs)
            end

            # Performs Continuation specific initialization
            def initialize_k
            end

            def onyx_class(terp)
                terp.globals[:Continuation]
            end

            def writeme
                raise "writeme"
            end

            # Does returning from this Continuation halt the Interpreter.
            def halt?
                false
            end

            def pretty_print_instance_variables
                [:@parent, :@env, :@rcvr, :@retk, :@marks]
            end

            # Restores saved values in the Continuation into the Interpreter, and
            # then passes the value to a Continuation specific action.
            # @param [Object] value
            def kontinue(value)
                @terp.restore(self)
                continue(value)
            end

            def delimited_with(tag)
                splice_onto(@parent.delimited_with(tag))
            end

            def erase_prompt(tag)
                @parent.erase_prompt(tag)
            end

            def compose(cont)
                splice_onto(@parent.compose(cont))
            end

            def splice_onto(parent)
                self.class.new(@terp, @env, @rcvr, @retk, parent, @marks, *kargs)
            end

            def find_first_mark(tag)
                if @marks.include?(tag) then
                    @marks[tag]
                else
                    @parent.find_first_mark(tag)
                end
            end

            def find_marks(tag)
                if @marks.include?(tag) then
                    [ @marks[tag] ] + @parent.find_marks(tag)
                else
                    @parent.find_marks(tag)
                end
            end
        end

        # XXX: HaltFrame should be removed.
        class HaltFrame < Frame
            def initialize(terp)
                super(terp, nil, nil, nil, nil, {})
            end

            def halt?
                true
            end

            def delimited_with(tag)
                self
            end

            def erase_prompt(tag)
                self
            end

            def compose(cont)
                cont
            end

            def find_first_mark(tag)
                if @marks.include?(tag) then
                    @marks[tag]
                else
                    nil
                end
            end

            def find_marks(tag)
                if @marks.include?(tag) then
                    [@marks[tag]]
                else
                    []
                end
            end
        end

        class SeqFrame < Frame
            def initialize_k(rest)
                @rest = rest
            end

            def kargs
                [@rest]
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

        class AssignFrame < Frame
            def initialize_k(var)
                @var = var
            end

            def kargs
                [@var]
            end

            def pretty_print_instance_variables
                super + [:@var]
            end

            def continue(value)
                @terp.assign_var(@var, value)
            end
        end

        module MsgFrameUtil
            def visit_message(message, rcvr)
                if message.unary? then
                    @terp.do_send(message.selector, rcvr, [])
                else
                    continue_message(message, rcvr, MsgFrame)
                end
            end

            def visit_primmessage(message, rcvr)
                if message.unary? then
                    @terp.do_primitive(message.selector, rcvr, [])
                else
                    continue_message(message, rcvr, PrimFrame)
                end
            end

            def continue_message(message, rcvr, kcls)
                selector = message.selector
                args = message.args
                @terp.push_k(kcls, selector, rcvr, args[1..-1])
                @terp.doing(args.first)
            end
        end

        class RcvrFrame < Frame
            include MsgFrameUtil

            def initialize_k(message)
                @message = message
            end

            def kargs
                [@message]
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

        class CascadeFrame < Frame
            include MsgFrameUtil

            def initialize_k(rcvr_val, messages)
                @rcvr_val = rcvr_val
                @messages = messages
            end

            def kargs
                [@rcvr_val, @messages]
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

        class MsgFrame < Frame
            def initialize_k(selector, rcvr_v, args, vals=[])
                @selector = selector
                @rcvr_v   = rcvr_v
                @args     = args
                @vals     = vals
            end

            def pretty_print_instance_variables
                super + [:@selector, :@rcvr_v, :@args, :@vals]
            end

            def kargs
                [@selector, @rcvr_v, @args, @vals]
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

        class PrimFrame < MsgFrame
            def do_send(vals)
                @terp.do_primitive(@selector, @rcvr_v, vals)
            end
        end

        class PromptFrame < Frame
            def initialize_k(tag)
                @tag = tag
            end

            def kargs
                [@tag]
            end

            def pretty_print_instance_variables
                super + [:@tag]
            end

            def continue(value)
            end

            def delimited_with(tag)
                if @tag == tag then
                    HaltFrame.new(@terp)
                else
                    super(tag)
                end
            end

            def erase_prompt(tag)
                if @tag == tag then
                    @parent
                else
                    super(tag)
                end
            end
        end

    end
end
