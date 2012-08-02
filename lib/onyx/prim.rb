
module Onyx
    class OnyxError < Exception
        attr_reader :exc

        def initialize(exc, msg)
            m = "an Exception (#{exc.onyx_class(nil).name.to_s}) was not caught in onyx: #{msg}"
            super(m)
            @exc = exc
            @msg = msg
        end
    end

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

        def prim_smallIntIsOdd(a)
            done((a & 1) == 1)
        end

        def prim_classNew(cls)
            done(cls.new_instance)
        end

        def prim_classSuperclass(cls)
            done(cls.super)
        end

        def prim_className(cls)
            done(cls.name)
        end

        def prim_blockValue(rcvr)
            do_block(rcvr)
        end

        def prim_blockValue_(rcvr, a)
            do_block(rcvr, [a])
        end

        def prim_blockValue_value_(rcvr, a, b)
            do_block(rcvr, [a, b])
        end

        def prim_blockWithPrompt_abort_(rcvr, tag, abort_handler)
            push_kprompt(tag, abort_handler)
            do_block(rcvr, [])
        end

        def prim_objectDebug(val)
            pp(val)
            done(val)
        end

        def prim_objectStackTrace(r)
            @stack.trace
            puts
            done(r)
        end

        def prim_objectAbort_(rcvr, tag)
            prompt_frame = @stack.find_prompt(tag)
            abort_handler = @stack[prompt_frame].abort_handler
            @stack.top = prompt_frame
            continue(nil)
            do_block(abort_handler, [rcvr])
        end

        def prim_systemIsBroken_(rcvr, msg)
            raise OnyxError.new(rcvr, msg)
        end

        def prim_blockWithCont_(rcvr, tag)
            dk = make_continuation(tag)
            do_block(rcvr, [dk])
        end

        def prim_blockWithMark_value_(rcvr, tag, value)
            @marks[tag] = value
            do_block(rcvr, [])
        end

        def prim_continuationDo_(cont, block)
            frames = cont.lookup(:frames).value
            add_continuation(frames)
            do_block(block, [])
        end

        def prim_continuationFirstMark_(cmark, prompt_tag)
            if @marks.include?(cmark) then
                val = @marks[cmark]
            else
                val = @stack.find_first_mark(cmark, prompt_tag)
            end
            done(val)
        end

        def prim_continuationMarks_(cmark, prompt_tag)
            v = []
            if @marks.include?(cmark) then
                v << @marks[cmark]
            end

            done(@stack.find_marks(cmark, prompt_tag, v))
        end

        def prim_arrayNew_(cls, size)
            done(Array.new(size))
        end

        def prim_arraySize(rcvr)
            done(rcvr.size)
        end

        def prim_arrayAt_put_(rcvr, i, j)
            if rcvr.onyx_immutable? then
                do_send(:immutableError, rcvr, [])
            else
                rcvr[i] = j
                done(j)
            end
        end

        def prim_arrayAt_(rcvr, i)
            done(rcvr[i])
        end

        def prim_arrayAppend_(a, b)
            done(a + b)
        end

        def prim_characterClassCodePoint_(rcvr, code_point)
            done(Char.code_point(code_point))
        end

        def prim_characterCodePoint(rcvr)
            done(rcvr.code_point)
        end

        def prim_objectClass(rcvr)
            done(rcvr.onyx_class(self))
        end

        def prim_stringSize(rcvr)
            done(rcvr.size)
        end

        def prim_stringAt_(rcvr, i)
            done(Char.code_point(rcvr[i]))
        end

        def prim_stringConcat_(rcvr, string)
            done(rcvr + string)
        end

        def prim_stringAsSymbol(string)
            done(string.to_sym)
        end

        def prim_symbolAsString(symbol)
            done(symbol.to_s)
        end
    end
end
