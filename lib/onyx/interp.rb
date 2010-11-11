
module Onyx

    class Interpreter
        attr_reader :globals

        def self.boot
            node = Parser.parse_file('system.ost')
            terp = self.new
            terp.eval(node)
            terp
        end

        def initialize
            @globals = GEnv.new
        end

        def eval(node)
            node.visit(self)
        end

        def visit_seq(seq)
            val = nil
            seq.nodes.each do | node |
                val = eval(node)
            end
            val
        end

        def build_mdict(meths)
            mdict = {}
            meths.each do | m |
                mdict[m.name] = 
                    OMethod.new(m.name, m.args, m.temps, m.stmts)
            end
            mdict
        end

        def visit_class(cls_node)
            super_cls = @globals.lookup(cls_node.supername).value
            name = cls_node.name
            mdict  = build_mdict(cls_node.meths)
            cmdict = build_mdict(cls_node.meta.meths)
            cls = OClass.new(name, super_cls, cls_node.ivars,
                cls_node.meta.ivars, mdict, cmdict)
            @globals.add_binding(name, cls)
        end
    end

    class InterpState
    end

end

