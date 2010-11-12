
module Onyx
    module Primitives
        def prim_addSmallInt_(a, b)
            prim_success(a + b)
        end

        def prim_mulSmallInt_(a, b)
            prim_success(a * b)
        end

        def prim_objectEqual_(a, b)
            prim_success(a == b)
        end

        def prim_smallIntLt_(a, b)
            prim_success(a < b)
        end

        def prim_classNew(cls)
            prim_success(cls.new_instance)
        end

        def prim_blockValue(rcvr)
            do_block(rcvr)
        end

        def prim_blockValue_(rcvr, a)
            do_block(rcvr, [a])
        end
    end
end
