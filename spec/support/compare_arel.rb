module RSpec
  module Matchers
    def self.different_arel_nodes(actual, expected, similar)
      actual_array = Arel.enhance(actual).each.to_a
      expected_array = Arel.enhance(expected).each.to_a

      actual_array.select.each_with_index do |actual_value, index|
        expected_value = expected_array[index]

        case actual_value.object
        when nil
          next false
        when true
          next false
        when false
          next false
        when Integer
          next false
        else
          similar ^ (expected_value.object.equal?(actual_value.object))
        end
      end
    end
  end
end

RSpec::Matchers.define :be_not_identical_arel do |expected|
  match do |actual|
    RSpec::Matchers.different_arel_nodes(actual, expected, false).length.zero?
  end

  failure_message do |actual|
    nodes = RSpec::Matchers.different_arel_nodes(actual, expected, false)
    message = "expected that these nodes would be different:\n\n"
    nodes.each do |node|
      message << "#{node.path.inspect}: #{node.object.class}\n"
    end
    message
  end
end

RSpec::Matchers.define :be_identical_arel do |expected|
  match do |actual|
    RSpec::Matchers.different_arel_nodes(actual, expected, true).length.zero?
  end

  failure_message do |actual|
    nodes = RSpec::Matchers.different_arel_nodes(actual, expected, true)
    message = "expected that these nodes would be the same:\n\n"
    nodes.each do |node|
      message << "#{node.path.inspect}: #{node.object.class}\n"
    end
    message
  end
end
