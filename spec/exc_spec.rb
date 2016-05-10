
describe Onyx::Interpreter do
    subject { Onyx::Interpreter.boot }

    it "exceptions: nothing signalled returns value of protected block" do
        should interpret('[ 42 ] on: Exception do: [:exc | 43 ]', 42)
    end

    it "exceptions: signalling an exception should run the exception block" do
        should interpret('[ Exception signal. 42 ] on: Exception do: [:exc | 43 ]', 43)
    end

    it "exceptions: passing on an exception should run the outer handler" do
        should interpret_script('spec/ost/exc_pass.ost', 42)
    end

    it "exceptions: resuming jumps back into protected block" do
        should interpret_script('spec/ost/exc_resume1.ost', 42)
    end

    it "exceptions: method lookups cause MessageNotUnderstood" do
        should interpret_script('spec/ost/exc_mnu.ost', true)
    end

    it "exceptions: isNested works" do
        should interpret_script('spec/ost/exc_isNested.ost', [true, false])
    end
end

