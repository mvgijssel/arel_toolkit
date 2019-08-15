module Arel
  module Middleware
    class ToSqlMiddleware
      attr_reader :sql, :type, :query_class

      def initialize(type)
        @sql = []
        @type = type
        @query_class = class_from_type
      end

      def call(next_arel, next_middleware)
        sql << next_arel.to_sql unless next_arel.query(class: query_class).empty?
        next_middleware.call(next_arel)
      end

      private

      def class_from_type
        case type
        when :insert
          Arel::Nodes::InsertStatement
        when :select
          Arel::Nodes::SelectStatement
        when :update
          Arel::Nodes::UpdateStatement
        when :delete
          Arel::Nodes::DeleteStatement
        end
      end
    end
  end
end
