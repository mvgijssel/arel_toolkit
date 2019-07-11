# rubocop:disable Naming/MethodName
# rubocop:disable Naming/UncommunicativeMethodParamName
# rubocop:disable Metrics/CyclomaticComplexity
# rubocop:disable Metrics/AbcSize

module Arel
  module Nodes
    # https://www.postgresql.org/docs/8.3/tutorial-transactions.html
    class Transaction < Arel::Nodes::Binary
      alias type left
      alias options right
    end
  end

  module Visitors
    class ToSql
      def visit_Arel_Nodes_Transaction(o, collector)
        case o.type
        when 0
          collector << 'BEGIN'
        when 2
          collector << 'COMMIT'
        when 3
          collector << 'ROLLBACK'
        when 4
          collector << 'SAVEPOINT '
          collector << o.options.join(' ')
        when 5
          collector << 'RELEASE SAVEPOINT '
          collector << o.options.join(' ')
        when 6
          collector << 'ROLLBACK TO '
          collector << o.options.join(' ')
        else
          raise "Unknown transaction type `#{o.type}`"
        end
      end
    end
  end
end

# rubocop:enable Naming/MethodName
# rubocop:enable Naming/UncommunicativeMethodParamName
# rubocop:enable Metrics/CyclomaticComplexity
# rubocop:enable Metrics/AbcSize
