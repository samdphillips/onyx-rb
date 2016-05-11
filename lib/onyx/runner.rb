
module Onyx
    class Runner
        def self.run(args)
            terp = Interpreter.boot
            args.each do |f|
                node = Parser.parse_file(f)
                terp.eval(node)
            end
        end
    end
end

