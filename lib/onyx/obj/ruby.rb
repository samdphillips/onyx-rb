
class Object
    def oclass?
        false
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

