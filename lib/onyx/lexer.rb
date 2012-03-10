
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

        def one_of(types)
            types.each do |t|
                if @type == t then
                    return true
                end
            end
            return false
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

    class LexEofError < LexError
        def message
            "Unexpected EOF"
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
            (?a .. ?z).each {|i| @char_table[i] = :id }
            (?A .. ?Z).each {|i| @char_table[i] = :id }
            " \t\n\r".each_byte {|i| @char_table[i] = :space }
            "`~!@%&*+=|\\?/<>,".each_byte {|i| @char_table[i] = :binsel }
            @char_table[?_] = :id
            @char_table[?:] = :colon
            @char_table[?-] = :dash
            @char_table[?^] = :caret
            @char_table[?(] = :lpar
            @char_table[?)] = :rpar
            @char_table[?[] = :lsq
            @char_table[?]] = :rsq
            @char_table[?.] = :dot
            @char_table[?;] = :semi
            @char_table[?"] = :comment
            @char_table[?'] = :string
            @char_table[?$] = :character
            @char_table[?#] = :hash
        end

        def self.char_scanners(*types)
            types.each do |t|
                name = "scan_#{t}".to_sym
                alias_method(name, :scan_char)
            end
        end

        def initialize(io=nil)
            unless io.nil? then
                self.io = io
            end
        end

        def io=(io)
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

        def eof_error
            raise LexEofError.new(self)
        end

        def scan_eof
            Token.new(:eof, :eof)
        end

        def scan_char
            tok = Token.new(cur_type, '' << cur_char)
            step
            tok
        end

        char_scanners :caret, :lpar, :rpar, :lsq, :rsq, :dot, :semi

        def scan_space
            while cur_type == :space do
                step
            end
            nil
        end

        def scan_comment
            step
            while cur_char != ?" do
                if cur_char.nil? then
                    eof_error
                end
                step
            end
            step
            nil
        end

        def scan_hash
            step
            if [:id, :binsel, :string].include?(cur_type) then
                scan_symbol
            else
                scan_error
            end
        end

        def scan_symbol
            if cur_type == :id then
                buf = read_id
                while true do
                    if cur_char == ?: then
                        buf << cur_char
                        step
                        buf = buf + read_id
                    else
                        break
                    end
                end

                Token.new(:symbol, buf.to_sym)
            elsif cur_type == :binsel then
                Token.new(:symbol, read_binsel.to_sym)
            elsif cur_type == :string then
                Token.new(:symbol, read_string.to_sym)
            else
                scan_error
            end
        end

        def scan_character
            step
            tok = Token.new(:character, cur_char)
            step
            tok
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

        def read_binsel
            buf = ''
            while cur_type == :binsel do
                buf << cur_char
                step
            end
            buf
        end

        def scan_binsel
            Token.new(:binsel, read_binsel.to_sym)
        end

        def read_id
            buf = ''
            while [:id, :digit].include? cur_type do
                buf << cur_char
                step
            end
            buf
        end

        def scan_id
            buf = read_id

            if cur_char == ?: then
                step
                Token.new(:kw, (buf + ':').to_sym)
            else
                Token.new(:id, buf.to_sym)
            end
        end

        def scan_colon
            step

            if cur_char == ?= then
                step
                Token.new(:assign, ':=')
            elsif cur_type == :id then
                Token.new(:blockarg, read_id.to_sym)
            else
                scan_error
            end
        end

        def read_string
            s = ""
            step

            while cur_char != ?' do
                if cur_char.nil? then
                    eof_error
                end
                s << cur_char
                step
            end

            step
            s
        end

        def scan_string
            Token.new(:string, read_string)
        end
    end
end

