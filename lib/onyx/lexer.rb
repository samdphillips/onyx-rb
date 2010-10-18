
module Onyx
    class Token
        attr_reader :type, :value

        def initialize(type, value=nil)
            @type  = type
            @value = value
        end

        def method_missing(sym, *args)
            s = sym.to_s
            if args == [] and s[-1] == ?? then
                @type == s[0...-1].to_sym
            else
                super.method_missing(sym, *args)
            end
        end
    end

    class LexError < Exception
        def initialize(lexer)
            @lexer = lexer
        end

        def message
            "Unexpected character: \"#{'' << @lexer.cur_char}\""
        end
    end

    class Lexer
        attr_reader :cur_char

        def self.char_table
            if @char_table.nil? then
                init_char_table
            end
            @char_table
        end

        def self.init_char_table
            @char_table = Array.new(256, :error)
            (?0 .. ?9).each {|i| @char_table[i] = :digit }
            " \t\n\r".each_byte {|i| @char_table[i] = :space }
            @char_table[?-] = :dash
        end

        def initialize(io)
            @io = io
            step
        end

        def step
            @cur_char = @io.getc
        end

        def char_table
            Lexer.char_table
        end

        def cur_type
            if cur_char.nil? then
                return :eof
            end

            char_table[cur_char]
        end

        def next
            tok = nil
            while tok.nil? do
                handler = "scan_#{cur_type}".to_sym
                tok = send(handler)
            end
            tok
        end

        def scan_error
            raise LexError.new(self)
        end

        def scan_space
            while cur_type == :space do
                step
            end
            nil
        end

        def read_number
            buf = ''

            while cur_type == :digit do
                buf << cur_char
                step
            end

            buf.to_i
        end

        def scan_digit
            i = read_number
            Token.new(:int, i)
        end

        def scan_dash
            step

            if cur_type == :digit then
                i = read_number
                Token.new(:int, -i)
            else
                s = read_binsel
                Token.new(:binsel, ('-' + s).to_sym)
            end
        end
    end
end

