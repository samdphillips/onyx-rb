
require 'stringio'

module Onyx
    class VmError < Exception
        def initialize(vm)
            @vm = vm
        end
    end

    class VmNameError < VmError
        def initialize(vm, name)
            super(vm)
            @name = name
        end

        def message
            "Name not defined: #{@name}"
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
            @stack   = Array.new(256)
            @sp      = 0
            @ip      = 0
            @method  = nil
            @rcvr    = nil
            @class   = nil
            @trace   = false
            @sysdict = {}
            boot
        end

        def boot
            object_class = OClass.new(:Object, nil)
            smi_class = OClass.new(:SmallInteger, object_class)
            add_class(object_class)
            add_class(smi_class)
        end

        def add_class(klass)
            @sysdict[klass.name] = klass
        end

        def doit(s)
            trace_print
            trace_print s
            p = Parser.new(StringIO.new(s))
            cg = p.parse_expr.compile
            @method = OMethod.new(cg.bytes << 0xFF, cg.literals)
            if @trace then
                puts
                puts "bytecode:"
                i = 0
                cg.bytes.each_byte do |b|
                    puts "  #{i} 0x#{b.to_s(16)}"
                    i = i + 1
                end
            end
            run
        end

        def find_class(class_name)
            if @sysdict.include? class_name then
                @sysdict[class_name]
            else
                raise VmNameError.new(self, class_name)
            end
        end

        def add_method(class_name, text)
            klass = find_class(class_name)
            p = Parser.new(StringIO.new(text))
            i = Compiler.new.compile(p.parse_method)
            m = Assembler.new.assemble(i)
            klass.add_method(m)
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

        def trace_print(s="")
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

            trace_print "op: 0x#{@op.to_s(16)}"
            high = @op >> 4
            
            if high == 0x0 then
                push_const
            elsif high == 0x8 then
                jump_false
            elsif high == 0x9 then
                jump
            elsif high == 0xA then
                do_smi_prim
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

            if low == 0xB then
                trace_print("push_const 0")
                push(0)
            elsif low == 0xC then
                trace_print("push_const 1")
                push(1)
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
            @ip = @ip + 1
            off = (@op & 0xF << 8) | code[@ip]
            @ip = @ip + 1
            a = pop

            if a == false then
                if (off & 0x800) != 0 then
                    off = -(4095 - off + 1)
                end
                @ip = @ip + off
                trace_print "jumping false to #{@ip}"
            else
                trace_print "not jumping false to #{@ip}"
            end
        end

        def jump
            @ip = @ip + 1
            off = (@op & 0xF << 8) | code[@ip]
            @ip = @ip + 1
            if (off & 0x800) != 0 then
                off = -(4095 - off + 1)
            end
            @ip = @ip + off
            trace_print "jumping to #{@ip}"
        end
    end
end
