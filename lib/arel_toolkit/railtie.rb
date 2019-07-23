module ArelToolkit
  class Railtie < ::Rails::Railtie
    initializer 'ArelToolkit.insert' do
      ActiveSupport.on_load :active_record do
        Arel::Middleware::Railtie.insert_postgresql
      end
    end
  end
end
