
require 'onyx'
require 'spec_helper'

RSpec::configure do |config|
      config.include(OnyxRSpecMatchers)
end

describe Onyx::Lexer do
    it { should lex(' ').to_tokens([:eof]) }
    it { should_not lex('"') }

    it { should lex('1234').to_token(:int, 1234) }
end

