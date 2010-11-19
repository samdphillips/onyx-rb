
module Onyx
    module Primitives
        def prim_addSmallInt_(a, b)
            done(a + b)
        end

        def prim_smallIntSub_(a, b)
            done(a - b)
        end

        def prim_smallIntQuo_(a, b)
            q,m = a.divmod(b)
            done(q)
        end

        def prim_mulSmallInt_(a, b)
            done(a * b)
        end

        def prim_objectEqual_(a, b)
            done(a == b)
        end

        def prim_smallIntLt_(a, b)
            done(a < b)
        end

        def prim_classNew(cls)
            done(cls.new_instance)
        end

        def prim_blockValue(rcvr)
            do_block(rcvr)
        end

        def prim_blockValue_(rcvr, a)
            do_block(rcvr, [a])
        end

        def prim_arrayNew_(cls, size)
            done(Array.new(size))
        end

        def prim_arraySize(rcvr)
            done(rcvr.size)
        end

        def prim_arrayAt_put_(rcvr, i, j)
            rcvr[i] = j
            done(j)
        end

        def prim_arrayAt_(rcvr, i)
            done(rcvr[i])
        end
    end
end