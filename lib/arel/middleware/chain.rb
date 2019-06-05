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

      def current
        internal_middleware
      end

      def models(models, &block)
        continue_chain(internal_middleware, models, internal_context, &block)
      end

      def apply(middleware, &block)
        continue_chain(middleware, internal_models, internal_context, &block)
      end

      def only(middleware, &block)
        continue_chain(middleware, internal_models, internal_context, &block)
      end

      def none(&block)
        continue_chain([], internal_models, internal_context, &block)
      end

      def except(without_middleware, &block)
        new_middleware = internal_middleware.reject do |middleware|
          middleware == without_middleware
        end

        continue_chain(new_middleware, internal_models, internal_context, &block)
      end

      def insert_before(new_middleware, existing_middleware, &block)
        index = internal_middleware.index(existing_middleware)
        updated_middleware = internal_middleware.insert(index, new_middleware)
        continue_chain(updated_middleware, internal_models, internal_context, &block)
      end

      def insert_after(new_middleware, existing_middleware, &block)
        index = internal_middleware.index(existing_middleware)
        updated_middleware = internal_middleware.insert(index + 1, new_middleware)
        continue_chain(updated_middleware, internal_models, internal_context, &block)
      end

      def context(new_context = nil, &block)
        if new_context.nil? && !block.nil?
          raise 'You cannot do a block statement while calling context without arguments'
        end

        return internal_context if new_context.nil?

        continue_chain(internal_middleware, internal_models, new_context, &block)
      end

      protected

      attr_reader :internal_middleware
      attr_reader :internal_models
      attr_reader :internal_context

      private

      def continue_chain(middleware, models, context, &block)
        new_chain = Arel::Middleware::Chain.new(middleware, models, context)
        maybe_execute_block(new_chain, &block)
      end

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
