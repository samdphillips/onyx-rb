
class Object
    def onyx_class?
        false
    end

    def onyx_immutable?
        not @onyx_immutable.nil? and @onyx_immutable
    end

    def onyx_immutable!
        @onyx_immutable = true
    end

    def include_ivar?(var)
        false
    end
end

class NilClass
    def onyx_class(terp)
        terp.globals[:UndefinedObject]
    end

    def to_s
        inspect
    end
end

class Fixnum
    def onyx_class(terp)
        terp.globals[:SmallInt]
    end
end

class FalseClass
    def onyx_class(terp)
        terp.globals[:False]
    end
end

class TrueClass
    def onyx_class(terp)
        terp.globals[:True]
    end
end

class Array
    def onyx_class(terp)
        terp.globals[:Array]
    end
end

class String
    def onyx_class(terp)
        terp.globals[:String]
    end
end

class Symbol
    def onyx_class(terp)
        terp.globals[:Symbol]
    end
end

