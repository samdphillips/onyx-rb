
module Onyx
    class Runner
        def self.run(args)
            begin
                terp = Interpreter.boot
                args.each do |f|
                    node = Parser.parse_file(f)
                    terp.eval(node)
                end
            rescue OnyxError => e
                puts 'Exception!'
                puts e
            end
        end
    end
end

