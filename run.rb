
require 'onyx'

i = Onyx::Interpreter.boot
pgm = Onyx::Parser.parse_file(ARGV[0])
i.eval(pgm)

