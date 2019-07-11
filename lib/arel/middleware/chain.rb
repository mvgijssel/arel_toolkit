module Arel
  module Middleware
    class Chain
      def initialize(internal_middleware = [], internal_context = {})
        @internal_middleware = internal_middleware
        @internal_context = internal_context
      end

      def execute(sql, binds = [])
        return sql if internal_middleware.length.zero?

        result = Arel.sql_to_arel(sql, binds: binds)
        updated_context = context.merge(original_sql: sql)

        internal_middleware.each do |middleware_item|
          result = result.map do |arel|
            middleware_item.call(arel, updated_context.dup)
          end
        end

        result.to_sql
      end

      def current
        internal_middleware.dup
      end

      def apply(middleware, &block)
        continue_chain(middleware, internal_context, &block)
      end

      def only(middleware, &block)
        continue_chain(middleware, internal_context, &block)
      end

      def none(&block)
        continue_chain([], internal_context, &block)
      end

      def except(without_middleware, &block)
        new_middleware = internal_middleware.reject do |middleware|
          middleware == without_middleware
        end

        continue_chain(new_middleware, internal_context, &block)
      end

      def insert_before(new_middleware, existing_middleware, &block)
        index = internal_middleware.index(existing_middleware)
        updated_middleware = internal_middleware.insert(index, new_middleware)
        continue_chain(updated_middleware, internal_context, &block)
      end

      def insert_after(new_middleware, existing_middleware, &block)
        index = internal_middleware.index(existing_middleware)
        updated_middleware = internal_middleware.insert(index + 1, new_middleware)
        continue_chain(updated_middleware, internal_context, &block)
      end

      def context(new_context = nil, &block)
        if new_context.nil? && !block.nil?
          raise 'You cannot do a block statement while calling context without arguments'
        end

        return internal_context if new_context.nil?

        continue_chain(internal_middleware, new_context, &block)
      end

      protected

      attr_reader :internal_middleware
      attr_reader :internal_context

      private

      def continue_chain(middleware, context, &block)
        new_chain = Arel::Middleware::Chain.new(middleware, context)
        maybe_execute_block(new_chain, &block)
      end

      def maybe_execute_block(new_chain, &block)
        return new_chain if block.nil?

        previous_chain = Middleware.current_chain
        Arel::Middleware.current_chain = new_chain
        yield block
      ensure
        Arel::Middleware.current_chain = previous_chain
      end
    end
  end
end
