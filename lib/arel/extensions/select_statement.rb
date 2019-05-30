module Arel
  module Nodes
    Arel::Nodes::SelectStatement.class_eval do
      # For INSERT statements
      attr_accessor :values_lists
    end
  end
end
