
require 'onyx'
require 'spec_helper'

RSpec::configure do |config|
    config.include(OnyxRSpecMatchers)
end

describe Onyx::Interpreter do
    subject { Onyx::Interpreter.boot }

    it "class of an object is Object" do
        should interpret('Object new class', subject.globals[:Object])
    end
end

