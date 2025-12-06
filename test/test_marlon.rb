# frozen_string_literal: true

require "test_helper"

class TestMarlon < Minitest::Test
  def test_that_it_has_a_version_number
    refute_nil ::Marlon::VERSION
  end

  def test_it_does_something_useful
    assert false
  end
end
