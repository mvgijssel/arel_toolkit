module Arel
  module Middleware
    class Chain
      def initialize(internal_middleware, internal_models)
        @internal_middleware = internal_middleware
        @internal_models = internal_models
      end

      def execute(sql, binds)
        arel = Arel.sql_to_arel(sql, models: internal_models, binds: binds)

        internal_middleware.each do |middleware_item|
          arel = middleware_item.call(arel)
        end

        arel.to_sql
      end

      def models(models, &block)
        new_chain = Arel::Middleware::Chain.new(internal_middleware, models)
        maybe_execute_block(new_chain, &block)
      end

      def apply(middleware, &block)
        new_chain = Arel::Middleware::Chain.new(middleware, internal_models)
        maybe_execute_block(new_chain, &block)
      end

      protected

      attr_reader :internal_middleware
      attr_reader :internal_models

      private

      def maybe_execute_block(new_chain, &block)
        return new_chain if block.nil?

        Arel::Middleware.current_chain = new_chain
        yield block
      ensure
        Arel::Middleware.current_chain = self
      end

      def current_chain
        Arel::Middleware.current_chain
      end
    end
  end
end
