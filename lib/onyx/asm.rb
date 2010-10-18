
require 'singleton'

module Onyx

    class Inst
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
            asm.code << 0x40
        end
    end

    ADD = AddOp.instance

    class MulOp < Inst
        include Singleton

        def assemble_with(asm)
            asm.code << 0x42
        end
    end

    MUL = MulOp.instance

    class LDC < Inst
        attr_reader :value

        def initialize(value)
            @value = value
        end

        def ==(other)
            self.class == other.class and
                value == other.value
        end

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

            ops.each do | op |
                op.assemble_with(self)
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
    end

end
