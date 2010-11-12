
class Object
    def oclass?
        false
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
