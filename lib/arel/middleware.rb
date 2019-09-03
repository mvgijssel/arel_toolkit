require_relative './middleware/active_record_extension'
require_relative './middleware/railtie'
require_relative './middleware/chain'
require_relative './middleware/database_executor'
require_relative './middleware/to_sql_executor'
require_relative './middleware/to_sql_middleware'
require_relative './middleware/result'
require_relative './middleware/column'
require_relative './middleware/postgresql'

module Arel
  module Middleware
    class << self
      def current_chain
        Thread.current[:arel_toolkit_middleware_current_chain] ||=
          Arel::Middleware::Chain.new
      end

      def current_chain=(new_chain)
        Thread.current[:arel_toolkit_middleware_current_chain] = new_chain
      end
    end
  end

  def self.middleware
    Arel::Middleware.current_chain
  end
end
