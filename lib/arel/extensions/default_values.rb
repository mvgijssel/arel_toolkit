# rubocop:disable Naming/MethodName

module Arel
  module Nodes
    # https://www.postgresql.org/docs/9.5/sql-insert.html
    class DefaultValues < Arel::Nodes::Node
    end
  end

  module Visitors
    class ToSql
      def visit_Arel_Nodes_DefaultValues(_o, collector)
        collector << 'DEFAULT VALUES'
      end
    end

    class Dot
      alias visit_Arel_Nodes_DefaultValues terminal
    end
  end
end

# rubocop:enable Naming/MethodName
