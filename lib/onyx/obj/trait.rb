
module Onyx
    class NullTrait
        def visit(thing)
            thing.visit_nulltrait(self)
        end

        def cls
            self
        end

        def include?(name)
            false
        end
    end

    class Trait
        def initialize(name, trait, mdict, cmdict)
            @name = name
            @trait = trait
            @mdict = mdict
            @cmdict = cmdict
        end

        def validate
            # XXX: need to complete
        end

        def cls
            @cmdict
        end

        def include?(name)
            @mdict.include?(name)
        end

        def [](name)
            @mdict[name]
        end
    end

    class TraitEval
        def initialize(globals)
            @globals = globals
        end

        def eval(node)
            node.visit(self)
        end

        def visit_ref(node)
            @globals.lookup(node.var).value
        end

        def visit_nulltrait(node)
            node
        end
    end
end
