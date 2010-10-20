
module Onyx
    class CodeGen
        SpecialConst = {0     => :push_zero,
                        1     => :push_one,
                        true  => :push_true,
                        false => :push_false,
                        nil   => :push_nil}

        attr_reader :bytes, :literals, :max_stack

        def initialize
            @literals    = []
            @bytes       = ''
            @stack_depth = 0
            @max_stack   = 0
            @label_count = 0
            @labels      = {}
        end

        def put_bytes(*bytes)
            bytes.each {|b| @bytes << b }
        end

        def stack_push
            @stack_depth = @stack_depth + 1
            @max_stack = [@max_stack, @stack_depth].max
        end

        def stack_pop
            if @stack_depth == 0 then
                raise Exception.new('stack underflow')
            end
            @stack_depth = @stack_depth - 1
        end

        def fresh_label
            @label_count = @label_count + 1
            "L#{@label_count}".to_sym
        end

        def new_label
            label = fresh_label
            @labels[label] = []
            label
        end

        def label_defined?(label)
            @labels[label].instance_of?(Fixnum)
        end

        def define_label(label)
            pos = @bytes.size
            patches = @labels[label]
            @labels[label] = pos
            patches.each do |p,i|
                send(p, i, pos - (i + 2))
            end
        end

        def signed_offset(n1, offset)
            s = offset & 0xFFF
            n2 = s >> 8
            [n1 | n2, s & 0xFF]
        end

        def patch_bytes(i, rbytes)
            rbytes.each do |b|
                @bytes[i] = b
                i = i + 1
            end
        end

        def patch_branch(i, offset)
            rbytes = signed_offset(@bytes[i], offset)
            patch_bytes(i, rbytes)
        end

        def push_const(value)
            if SpecialConst.include?(value) then
                send(SpecialConst[value])
            else
                pos = add_literal(value)
                push_lit(pos)
            end
        end

        def add_literal(value)
            p = @literals.index(value)

            if p.nil? then
                p = @literals.size
                @literals << value
            end
            p
        end

        def push_lit(pos)
            if pos < 10 then
                put_bytes(pos)
            elsif pos < 265
                put_bytes(0x0A, pos - 10)
            end
            stack_push
        end

        def push_zero
            put_bytes(0x0B)
            stack_push
        end

        def push_one
            put_bytes(0x0C)
            stack_push
        end

        def push_true
            put_bytes(0x0D)
            stack_push
        end

        def push_false
            put_bytes(0x0E)
            stack_push
        end

        def push_nil
            put_bytes(0x0F)
            stack_push
        end

        def prim_add
            put_bytes(0xA0)
            stack_pop
        end

        def prim_mul
            put_bytes(0xA2)
            stack_pop
        end

        def branch_false(label)
            if label_defined?(label) then
                pos = bytes.size
                put_bytes(*signed_offset(0x80, @labels[label] - (pos + 2)))
            else
                @labels[label] << [:patch_branch, bytes.size]
                put_bytes(0x80, 0x00)
            end
        end

        def branch(label)
            if label_defined?(label) then
                pos = bytes.size
                put_bytes(*signed_offset(0x90, @labels[label] - (pos + 2)))
            else
                @labels[label] << [:patch_branch, bytes.size]
                put_bytes(0x90, 0x00)
            end
        end
    end
end

