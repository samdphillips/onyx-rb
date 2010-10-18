
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

        def initialize(method)
            @method = method
            @is_running = false
            @stack = Array.new(256)
            @sp = 0
            @ip = 0
            @trace = false
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

        def tos
            @stack[@sp - 1]
        end

        def trace_print(s)
            if @trace then
                puts s
            end
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
            
            if high == 0 then
                push_const
            elsif high == 0xF then
                if @op == 0xFF then
                    @is_running = false
                else
                    do_primitive
                end
            else
                raise OpError.new(self)
            end
        end

        def push_const
            low = @op & 0xF
            trace_print("push_const #{low}")

            if low == 0xA then
                push(0)
            elsif low == 0xB then
                push(1)
            elsif low == 0xC then
                push(-1)
            else
                push(lits[low])
            end
            @ip = @ip + 1
        end
    end
end
