
require 'onyx'
require 'spec_helper'

RSpec::configure do |config|
    config.include(OnyxRSpecMatchers)
end

describe Onyx::Lexer do
    it { should lex(' ').to_token(:eof) }
    it { should_not lex('"') }

    it { should lex('1234').to_token(:int, 1234) }
    it { should lex('    1234').to_token(:int, 1234) }
    it { should lex('"comment"    1234').to_token(:int, 1234) }
    it { should lex('-1').to_token(:int, -1) }

    it { should lex('+').to_token(:binsel, :+) }
    it { should lex('-').to_token(:binsel, :-) }

    it { should lex('$a').to_token(:character, ?a) }

    it { should lex("'test string'").to_token(:string, 'test string') }

    it { should lex('#aUnarySymbol').to_token(:symbol, :aUnarySymbol) }
    it { should lex('#+').to_token(:symbol, :+) }
    it { should lex('#aKeyword:symbol:').to_token(:symbol, :'aKeyword:symbol:') }
    it { should lex("#'another symbol'").to_token(:symbol, :'another symbol') }

    it { should lex('abc123').to_token(:id, :abc123) }
    it { should lex('_new').to_token(:id, :_new) }

    it { should lex('at:').to_token(:kw, :'at:') }
    it { should lex('_new:').to_token(:kw, :'_new:') }

    it { should lex(':a').to_token(:blockarg, :a) }

    it { should lex('^').to_token(:caret) }
    it { should lex(';').to_token(:semi) }
    it { should lex('( )').to_tokens(:lpar, :rpar) }

    it { should lex('#( )').to_tokens(:lparray, :rpar) }
end

