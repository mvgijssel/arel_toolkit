# rubocop:disable Metrics/ParameterLists
# rubocop:disable Naming/UncommunicativeMethodParamName
# rubocop:disable Metrics/ModuleLength

module Arel
  module Nodes
    # https://www.postgresql.org/docs/9.5/sql-insert.html
    class DefaultValues < Arel::Nodes::Node
    end

    # https://www.postgresql.org/docs/9.5/sql-insert.html
    class DefaultValues < Arel::Nodes::Node
    end

    # https://www.postgresql.org/docs/9.5/sql-insert.html
    class Conflict < Arel::Nodes::Node
      attr_accessor :action
      attr_accessor :infer
      attr_accessor :values
      attr_accessor :wheres
    end

    # https://www.postgresql.org/docs/9.5/sql-insert.html
    class Infer < Arel::Nodes::Node
      attr_accessor :name
      attr_accessor :indexes
    end

    # https://www.postgresql.org/docs/9.5/sql-insert.html
    class SetToDefault < Arel::Nodes::Node
    end

    # https://www.postgresql.org/docs/10/sql-update.html
    Arel::Nodes::UpdateStatement.class_eval do
      attr_accessor :with
      attr_accessor :froms
      attr_accessor :returning
    end

    # https://www.postgresql.org/docs/10/sql-update.html
    class CurrentOfExpression < Arel::Nodes::Node
      attr_accessor :cursor_name

      def initialize(cursor_name)
        super()

        @cursor_name = cursor_name
      end
    end

    # https://www.postgresql.org/docs/9.5/sql-insert.html
    Arel::Nodes::DeleteStatement.class_eval do
      attr_accessor :using
      attr_accessor :with
      attr_accessor :returning
    end
  end
end

# rubocop:enable Metrics/ParameterLists
# rubocop:enable Naming/UncommunicativeMethodParamName
# rubocop:enable Metrics/ModuleLength
