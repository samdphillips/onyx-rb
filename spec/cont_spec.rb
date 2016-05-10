
describe Onyx::Interpreter do
    subject { Onyx::Interpreter.boot }

    it "continuation marks: multiple marked values should be returned as an Array" do
        should interpret('
            p := PromptTag new.
            m := ContinuationMark new.
            [
                [
                    [
                        [ p abort: (m marks: p) ] withMark: m value: 1.
                        #foo
                    ] withMark: m value: 2.
                    #foo 
                ] withMark: m value: 3
            ] withPrompt: p
            ', [1,2,3])
    end

    it "continuation marks: aborts should restore correct marks" do
       should interpret_script('spec/ost/cmark2.ost', ['last'])
    end

    it "ifCurtailed: block should be run if an exception is signalled" do
       should interpret_script('spec/ost/curtailed1.ost', 42)
    end

    it "ifCurtailed: all blocks should be run ifCurtailed" do
       should interpret_script('spec/ost/curtailed2.ost', 43)
    end

end

