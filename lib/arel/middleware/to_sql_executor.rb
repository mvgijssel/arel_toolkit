module Arel
  module Middleware
    class ToSqlExecutor < DatabaseExecutor
      private

      def execute_sql(next_arel)
        Arel::Table.engine.connection.sql_without_execution(next_arel.to_sql)
      end
    end
  end
end
