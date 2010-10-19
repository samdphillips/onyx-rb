
require 'stringio'

module Onyx
    class VmError < Exception
        def initialize(vm)
            @vm = vm
        end
    end

    class OpError < VmError
        def message
            "Invalid op: 0x#{@vm.op.to_s(16)}"
        end
    end

    class OVM
        attr_accessor :trace
        attr_reader :op

        def initialize
            @is_running = false
            @stack = Array.new(256)
            @sp = 0
            @ip = 0
            @trace = false
        end

        def doit(s)
            p = Parser.new(StringIO.new(s))
            i = Compiler.new.compile(p.parse_expr)
            @method = Assembler.new.assemble(i << HALT)
            run
        end

        def code
            @method.code
        end

        def lits
            @method.lits
        end

        def push(value)
            @stack[@sp] = value
            @sp = @sp + 1
        end

        def pop
            @sp = @sp - 1
            @stack[@sp]
        end

        def tos
            @stack[@sp - 1]
        end

        def trace_print(s)
            if @trace then
                puts s
            end
        end

        def op_error
            raise OpError.new(self)
        end

        def run
            @is_running = true

            while @is_running do
                step
            end

            self
        end

        def step
            @op = code[@ip]

            high = @op >> 4
            
            if high == 0x0 then
                push_const
            elsif high == 0x4 then
                do_smi_prim
            elsif high == 0x6 then
                jump_false
            elsif high == 0x7 then
                jump
            elsif high == 0xF then
                if @op == 0xFF then
                    @is_running = false
                else
                    do_prim
                end
            else
                op_error
            end
        end

        def push_const
            low = @op & 0xF

            if low == 0xA then
                trace_print("push_const 0")
                push(0)
            elsif low == 0xB then
                trace_print("push_const 1")
                push(1)
            elsif low == 0xC then
                trace_print("push_const -1")
                push(-1)
            elsif low == 0xD then
                trace_print("push_const true")
                push(true)
            elsif low == 0xE then
                trace_print("push_const false")
                push(false)
            elsif low == 0xF then
                trace_print("push_const nil")
                push(nil)
            else
                v = lits[low]
                trace_print("push_lit #{v}")
                push(v)
            end
            @ip = @ip + 1
        end

        def do_smi_prim
            low = @op & 0xF
            a = pop
            b = pop

            if low == 0x0 then
                push(a + b)
            elsif low == 0x2 then
                push(a * b)
            else
                op_error
            end

            @ip = @ip + 1
        end

        def jump_false
            low = @op & 0xF
            a = pop

            # FIXME: negative jumps
            if a == false then
                @ip = @ip + low
            else
                @ip = @ip + 1
            end
        end

        def jump
            @ip = @ip + (@op & 0xF)
        end
    end
end
