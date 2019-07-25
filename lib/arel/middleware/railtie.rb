module Arel
  module Middleware
    if defined? Rails::Railtie
      class Railtie < Rails::Railtie
        initializer 'arel.middleware.insert' do
          ActiveSupport.on_load :active_record do
            Arel::Middleware::Railtie.insert_postgresql
          end
        end
      end
    end

    class Railtie
      def self.insert_postgresql
        ActiveRecord::ConnectionAdapters::PostgreSQLAdapter.prepend(
          Arel::Middleware::PostgreSQLAdapter,
        )
      end
    end
  end
end
