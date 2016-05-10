
describe Onyx::Interpreter do
    subject { Onyx::Interpreter.boot }

    it "class of an object is Object" do
        should interpret('Object new class', subject.globals[:Object])
    end

    it "object is a kind of Object" do
        should interpret('Object new isKindOf: Object', true)
    end

    it "object is not a kind of Array" do
        should interpret('Object new isKindOf: Array', false)
    end

    it "Array object is a kind of object" do
        should interpret('(Array new: 8) isKindOf: Object', true)
    end

    it "Array object is a kind of Array" do
        should interpret('(Array new: 8) isKindOf: Array', true)
    end

    it "Array object is a kind of Collection" do
        should interpret('(Array new: 8) isKindOf: Collection', true)
    end

    it "object is a member of object" do
        should interpret('Object new isMemberOf: Object', true)
    end

    it "object is not a member of Array" do
        should interpret('Object new isMemberOf: Array', false)
    end

    it "Array object is a member of Array" do
        should interpret('(Array new: 8) isMemberOf: Array', true)
    end

    it "Array object is not a member of Object" do
        should interpret('(Array new: 8) isMemberOf: Object', false)
    end

end

