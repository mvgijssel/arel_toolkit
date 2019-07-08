# typed: true
# rubocop:disable Naming/MethodName
# rubocop:disable Naming/UncommunicativeMethodParamName
# rubocop:disable Metrics/CyclomaticComplexity
# rubocop:disable Metrics/AbcSize

module Arel
  module Nodes
    # https://www.postgresql.org/docs/8.3/tutorial-transactions.html
    class Transaction < Arel::Nodes::Node
      attr_reader :type
      attr_reader :options

      sig { params(type: Integer, options: T::Array[String]).void }
      def initialize(type, options)
        @type = type
        @options = options
      end
    end
  end

  module Visitors
    class ToSql
      sig { params(o: Arel::Nodes::Transaction, collector: Arel::Collectors::SQLString).returns(Arel::Collectors::SQLString) }
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