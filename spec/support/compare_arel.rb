module RSpec
  module Matchers
    def self.different_arel_nodes(actual, expected, similar)
      actual_tree = Arel.transformer(actual)
      actual_array = actual_tree.to_a
      expected_tree = Arel.transformer(expected)
      expected_array = expected_tree.to_a

      actual_array.select.each_with_index do |actual_value, index|
        expected_value = expected_array[index]

        case actual_value.object
        when nil
          next false
        when Integer
          next false
        else
          similar ^ (expected_value.object.object_id == actual_value.object.object_id)
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
