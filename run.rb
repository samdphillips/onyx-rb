
require 'onyx'

i = Onyx::Interpreter.boot
pgm = Onyx::Parser.parse_file(ARGV[0])

begin
    puts i.eval(pgm)
rescue Onyx::OnyxError => e
    pp e.exc
    raise e
end

