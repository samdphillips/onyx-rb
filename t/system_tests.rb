
require 'onyx'

module SystemTest
    include Onyx

    def setup
        @terp = Interpreter.boot
        @terp.eval_file("t/system_tests/#{ost_file}")
    end

    def assert_env(var, value)
        assert_equal(value, @terp.globals[var])
    end
end

