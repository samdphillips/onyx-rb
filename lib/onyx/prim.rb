
module Onyx
    module Primitives
        def prim_addSmallInt_(a, b)
            prim_success(a + b)
        end

        def prim_smallIntSub_(a, b)
            prim_success(a - b)
        end

        def prim_smallIntQuo_(a, b)
            q,m = a.divmod(b)
            prim_success(q)
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

        def prim_arrayNew_(cls, size)
            prim_success(Array.new(size))
        end

        def prim_arraySize(rcvr)
            prim_success(rcvr.size)
        end

        def prim_arrayAt_put_(rcvr, i, j)
            rcvr[i] = j
            prim_success(j)
        end

        def prim_arrayAt_(rcvr, i)
            prim_success(rcvr[i])
        end
    end
end
