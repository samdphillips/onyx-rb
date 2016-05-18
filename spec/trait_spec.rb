
describe Onyx::Interpreter do
    subject do
        i = Onyx::Interpreter.boot
        i.eval_file('spec/ost/traits.ost')
        i
    end

    it "traits: self is bound to object in trait method" do
        should interpret('Bar test', 'foo barfoo')
        should interpret('Baz test', 'foo bazfoo')
    end
end

