# typed: true
module Arel
  module Middleware
    class Railtie
      sig { returns(Class) }
      def self.insert_postgresql
        ActiveRecord::ConnectionAdapters::PostgreSQLAdapter.prepend(
          Arel::Middleware::PostgreSQLAdapter,
        )
      end
    end
  end
end