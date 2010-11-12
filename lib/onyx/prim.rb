
module Onyx
    module Primitives
        def prim_addSmallInt_(a, b)
            a + b
        end

        def prim_mulSmallInt_(a, b)
            a * b
        end

        def prim_objectEqual_(a, b)
            a == b
        end

        def prim_smallIntLt_(a, b)
            a < b
        end

        def prim_classNew(cls)
            cls.new_instance
        end
    end
end
