module Arel
  if defined? Rails::Railtie
    require 'rails/railtie'

    class Railtie < Rails::Railtie
      initializer 'ArelToolkit.insert' do
        ActiveSupport.on_load :active_record do
          Arel::Middleware::Railtie.insert_postgresql
        end
      end
    end
  end

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
