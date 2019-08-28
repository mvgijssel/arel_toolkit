module Arel
  module Middleware
    if defined? Rails::Railtie
      class Railtie < Rails::Railtie
        initializer 'arel.middleware.insert' do
          ActiveSupport.on_load :active_record do
            Arel::Middleware::Railtie.insert
          end
        end
      end
    end

    class Railtie
      def self.insert
        ActiveRecord::ConnectionAdapters::PostgreSQLAdapter.prepend(
          Arel::Middleware::Postgresql::Adapter,
        )

        ActiveRecord::Base.singleton_class.prepend(
          Arel::Middleware::ActiveRecordExtension,
        )
      end
    end
  end
end
