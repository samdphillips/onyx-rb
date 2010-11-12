
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

