
require 'onyx'

class Debugger < Onyx::Interpreter
    class Doing < Onyx::Interpreter::Doing
        def step
            super
        end
    end

    def initialize(*args)
        super
        @breakpoints = {}
    end

    def doing(node)
        @tramp = Doing.new(self, node)
    end
end

i = Debugger.boot
pgm = Onyx::Parser.parse_file(ARGV[0])

begin
    puts i.eval(pgm)
rescue Onyx::OnyxError => e
    pp e.exc
    raise e
end


