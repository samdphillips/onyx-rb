
describe Onyx::Interpreter do
    subject(:terp) do
        i = Onyx::Interpreter.boot
        i.eval_file('spec/ost/traits.ost')
        i
    end

    it "traits: self is bound to object in trait method" do
        should interpret('Bar test', 'foo barfoo')
        should interpret('Baz test', 'foo bazfoo')
    end

    it "traits: trait union contains all methods" do
        terp.eval_string("TABCDEF := TABC + TDEF.")
        terp.eval_string("Object subclass: ABCDEF [ ABCDEF uses: TABCDEF. ]")
        should interpret('ABCDEF new a', 1)
        should interpret('ABCDEF new b', 2)
        should interpret('ABCDEF new c', 3)
        should interpret('ABCDEF new d', 4)
        should interpret('ABCDEF new e', 5)
        should interpret('ABCDEF new f', 6)
    end

    it "traits: trait union from array" do
        terp.eval_string("Object subclass: ABCDEF [ ABCDEF uses: {TABC. TDEF}. ]")
        should interpret('ABCDEF new a', 1)
        should interpret('ABCDEF new b', 2)
        should interpret('ABCDEF new c', 3)
        should interpret('ABCDEF new d', 4)
        should interpret('ABCDEF new e', 5)
        should interpret('ABCDEF new f', 6)
    end

    it "traits: trait union with empty array" do
        terp.eval_string("Object subclass: ABC [ ABC uses: TABC + { }. ]")
        should interpret('ABC new a', 1)
        should interpret('ABC new b', 2)
        should interpret('ABC new c', 3)
    end
end

