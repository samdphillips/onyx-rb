
require 'onyx'
require 't/system_tests'
require 'test/unit'

class TestInterval < Test::Unit::TestCase
    include SystemTest

    def ost_file
        "interval.ost"
    end

    def test_start
        assert_env(:a, 1)
    end

    def test_stop
        assert_env(:b, 10)
    end

    def test_step
        assert_env(:c, 1)
    end

    def test_start_dec
        assert_env(:d, 10)
    end

    def test_stop_dec
        assert_env(:e, 1)
    end

    def test_step_dec
        assert_env(:f, -1)
    end

    def test_vals
        assert_env(:g, [1, 2, 3, 4, 5, 6, 7, 8, 9, 10])
    end

    def test_vals_dec
        assert_env(:h, [10, 9, 8, 7, 6, 5, 4, 3, 2, 1])
    end

    def test_size
        assert_env(:i, 10)
    end

    def test_size_dec
        assert_env(:j, 10)
    end

    def test_size_by_2
        assert_env(:k, 3)
    end

    def test_size_by_3
        assert_env(:l, 4)
    end

    def test_size_dec_by_3
        assert_env(:m, 4)
    end

    def test_vals_by_3
        assert_env(:n, [1, 4, 7, 10])
    end

    def test_select
        assert_env(:o, [1, 3, 5, 7, 9])
    end
end

