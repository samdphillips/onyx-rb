
require 'singleton'

module Onyx

    class Inst
    end

    class Label
        attr_reader :tag

        def initialize(tag)
            @tag = tag
        end

        def assemble_with(asm)
            asm.add_label(self)
        end
    end

    class HaltOp < Inst
        include Singleton

        def assemble_with(asm)
            asm.code << 0xFF
        end
    end

    HALT = HaltOp.instance

    class AddOp < Inst
        include Singleton

        def assemble_with(asm)
            asm.code << 0xA0
        end
    end

    ADD = AddOp.instance

    class MulOp < Inst
        include Singleton

        def assemble_with(asm)
            asm.code << 0xA2
        end
    end

    MUL = MulOp.instance

    class Jump < Inst
        attr_reader :dest

        def initialize(dest)
            @dest = dest
        end

        # FIXME: need more robust code for negative offsets
        # FIXME: bigger jumps
        def assemble_with(asm)
            off = asm.label_offset(@dest)

            if off.nil? then
                asm.pending_label(self)
                asm.code << base_inst
            else
                asm.code << (base_inst | off)
            end
        end

        def patch(asm, i)
            off = asm.label_offset(@dest, i)

            if off.nil? then
                raise AssemblerError.new("label never defined #{@dest}")
            end

            base_inst | off
        end
    end

    class JMPF < Jump
        def base_inst
            0x80
        end
    end

    class JMP < Jump
        def base_inst
            0x90
        end
    end

    class LDC < Inst
        attr_reader :value

        def initialize(value)
            @value = value
        end

        def ==(other)
            self.class == other.class and
                value == other.value
        end

        # FIXME: need to consider accessing more than 10 literals
        def assemble_with(asm)
            if value == 0 then
                asm.code << 0x0A
            elsif value == 1 then
                asm.code << 0x0B
            elsif value == -1 then
                asm.code << 0x0C
            elsif value == true then
                asm.code << 0x0D
            elsif value == false then
                asm.code << 0x0E
            elsif value == nil then
                asm.code << 0x0F
            else
                pos = asm.add_lit(value)
                asm.code << pos
            end
        end
    end

    class Assembler
        attr_accessor :code
        
        def assemble(ops)
            @code = ''
            @lits = []
            @labels = {}
            @pending = {}

            ops.each do | op |
                op.assemble_with(self)
            end

            @pending.each_pair do |op, i|
                @code[i] = op.patch(self, i)
            end

            Method.new(@code, @lits)
        end

        def add_lit(value)
            @lits.each_index do | i |
                if @lits[i] == value then
                    return i
                end
            end

            i = @lits.size
            @lits << value
            return i
        end

        def label_offset(label, i=nil)
            if i.nil? then
                i = @code.size
            end

            if @labels.include? label then
                @labels[label] - i
            else
                nil
            end
        end

        def add_label(label)
            @labels[label] = @code.size
        end

        def pending_label(inst)
            @pending[inst] = @code.size
        end
    end

end
