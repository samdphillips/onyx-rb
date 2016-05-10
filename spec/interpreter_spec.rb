
describe Onyx::Interpreter do
    subject { Onyx::Interpreter.boot }

    it "perform basic fixnum operations" do
        should interpret('3 + 4', 7)
        should interpret('3 + 4 * 2', 14)
        should interpret('3 isNumber', true)
        should interpret('3 = 3', true)
        should interpret('3 = 4', false)

        should interpret("1 isOdd", true)
        should interpret("2 isOdd", false)
        should interpret("3 isOdd", true)
        should interpret("4 isOdd", false)

        should interpret("3 // 4", 0)
        should interpret("8 // 4", 2)
        should interpret("9 // 4", 2)
        should interpret("6 // 4", 1)
    end

    it "evaluates blocks" do
        should interpret("[ 3 ] value", 3)
        should interpret("[:a | a ] value: 10", 10)
        should interpret("a := 0. [:a | a ] value: 10", 10)
    end
end

