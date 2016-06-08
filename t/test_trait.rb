
require 'onyx'
require 't/system_tests'
require 'test/unit'

class TestTrait < Test::Unit::TestCase
    include SystemTest

    def ost_file
        "trait.ost"
    end

    def test_invalid_trait
        assert_env(:missingRaised, true)
    end

end

