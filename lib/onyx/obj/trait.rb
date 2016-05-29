
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
    end
end

