module Arel
  module Middleware
    class Railtie
      def self.insert_postgresql
        ActiveRecord::ConnectionAdapters::PostgreSQLAdapter.prepend(
          Arel::Middleware::PostgreSQLAdapter,
        )
      end
    end
  end
end
