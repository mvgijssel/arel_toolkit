module Arel
  module Middleware
    class ToSqlExecutor < DatabaseExecutor
      private

      def execute_sql(next_arel)
        Arel::Middleware::Result.create(
          data: next_arel.to_sql,
          from: Arel::Middleware::StringResult,
          to: Arel::Middleware::EmptyPGResult
        )
      end
    end
  end
end
