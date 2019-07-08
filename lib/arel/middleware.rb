# typed: true
require 'active_record'
require_relative './middleware/railtie'
require_relative './middleware/chain'
require_relative './middleware/postgresql_adapter'

module Arel
  module Middleware
    class << self
      sig { returns(Arel::Middleware::Chain) }
      def current_chain
        Thread.current[:arel_toolkit_middleware_current_chain] ||=
          Arel::Middleware::Chain.new
      end

      sig { params(new_chain: Arel::Middleware::Chain).returns(Arel::Middleware::Chain) }
      def current_chain=(new_chain)
        Thread.current[:arel_toolkit_middleware_current_chain] = new_chain
      end
    end
  end

  sig { returns(Arel::Middleware::Chain) }
  def self.middleware
    Arel::Middleware.current_chain
  end
end