
require 'onyx'
require 'spec_helper'

RSpec::configure do |config|
    config.include(OnyxRSpecMatchers)
end

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

end

