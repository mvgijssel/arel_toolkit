module Arel
  module Middleware
    class Railtie
      def self.insert_postgresql
        ActiveRecord::ConnectionAdapters::PostgreSQLAdapter.class_eval do
          include Arel::Middleware::PostgreSQLAdapter
        end
      end
    end
  end
end
