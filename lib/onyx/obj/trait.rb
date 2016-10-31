
require 'set'

module Onyx
    class Trait
        attr_reader :mdict

        def initialize(name, mdict, cmdict)
            @name = name
            @mdict = mdict
            @cmdict = cmdict
        end

        def onyx_class(terp)
            terp.globals[:Trait]
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

        def add_trait(trait)
            merge(trait)
        end

        def merge(trait)
            trait.mdict.each_pair do |k,m|
                unless @mdict.include? k then
                    @mdict[k] = m
                end
            end

            trait.cls.each_pair do |k,m|
                unless @cmdict.include? k then
                    @cmdict[k] = m
                end
            end
        end

        def rename(src, dest)
            @mdict[dest] = @mdict.delete(src)
        end

        def remove(mname)
            @mdict.delete(mname)
        end

        def needed_methods
            Enumerator.new do |y|
                v = SelfSendVisitor.new(y)
                @mdict.values.each do |m|
                    m.stmts.visit(v)
                end
            end
        end

        def validate(cls)
            ret = []
            needed_methods.each do |n|
                if not include?(n) and cls.instance_lookup_method(nil, n).nil? then
                    ret << n
                end
            end
            ret
        end
    end

    class SelfSendVisitor
        def initialize(y)
            @yield = y
            @seen = Set.new
        end

        def is_self?(node)
            node.class == RefNode and node.var == :self
        end

        def not_seen?(selector)
            not @seen.include?(selector)
        end

        def visit_assign(assign)
            assign.expr.visit(self)
        end

        def visit_block(blk)
            blk.stmts.visit(self)
        end

        def visit_const(const)
        end

        def visit_send(send)
            selector = send.message.selector
            # XXX: check for primitive?
            if is_self?(send.rcvr) and not_seen?(selector) then
                @yield << selector
                @seen << selector
            else
                send.rcvr.visit(self)
            end

            send.message.args.each do |arg|
                arg.visit(self)
            end
        end

        def visit_seq(seq)
            seq.nodes.each do |node|
                node.visit(self)
            end
        end

        def visit_ref(ref)
        end

        def visit_return(ret)
            ret.expr.visit(self)
        end
    end
end
