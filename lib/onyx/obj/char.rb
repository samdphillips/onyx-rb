
module Onyx
    class Char
        def self.code_point(i)
            if @char_table.nil? then
                init_char_table
            end

            if @char_table[i].nil? then
                @char_table[i] = self.new(i)
            end

            @char_table[i]
        end

        def self.init_char_table
            @char_table = Hash.new
        end

        attr_reader :code_point

        def initialize(code_point)
            @code_point = code_point
        end

        def onyx_class(terp)
            terp.globals[:Character]
        end
    end
end
