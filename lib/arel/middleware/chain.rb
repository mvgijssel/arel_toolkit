module Arel
  module Middleware
    class Chain
      def initialize(internal_middleware, internal_models, internal_context)
        @internal_middleware = internal_middleware
        @internal_models = internal_models
        @internal_context = internal_context
      end

      def execute(sql, binds)
        arel = Arel.sql_to_arel(sql, models: internal_models, binds: binds)

        internal_middleware.each do |middleware_item|
          arel = middleware_item.call(arel)
        end

        arel.to_sql
      end

      def models(models, &block)
        new_chain = Arel::Middleware::Chain.new(internal_middleware, models, internal_context)
        maybe_execute_block(new_chain, &block)
      end

      def apply(middleware, &block)
        new_chain = Arel::Middleware::Chain.new(middleware, internal_models, internal_context)
        maybe_execute_block(new_chain, &block)
      end

      def except(without_middleware, &block)
        new_middleware = internal_middleware.reject do |middleware|
          middleware == without_middleware
        end

        new_chain = Arel::Middleware::Chain.new(new_middleware, internal_models, internal_context)
        maybe_execute_block(new_chain, &block)
      end

      def current
        internal_middleware
      end

      def context(new_context = nil, &block)
        if new_context.nil? && !block.nil?
          raise 'You cannot do a block statement while calling context without arguments'
        end

        return internal_context if new_context.nil?

        new_chain = Arel::Middleware::Chain.new(internal_middleware, internal_models, new_context)
        maybe_execute_block(new_chain, &block)
      end

      protected

      attr_reader :internal_middleware
      attr_reader :internal_models
      attr_reader :internal_context

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
