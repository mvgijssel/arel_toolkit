module Arel
  module Middleware
    class Chain
      attr_reader :executing_middleware

      class MiddlewareExecutor
        attr_reader :middleware
        attr_reader :next_executor
        attr_reader :context

        def initialize(middleware, next_executor, context)
          @middleware = middleware
          @next_executor = next_executor
          @context = context
        end

        def call(next_arel)
          case middleware.method(:call).arity
          when 2
            middleware.call(next_arel, next_executor)
          else
            middleware.call(next_arel, next_executor, context)
          end
        end
      end

      class SqlExecutor
        attr_reader :execute_sql
        attr_reader :binds

        def initialize(execute_sql, binds)
          @execute_sql = execute_sql
          @binds = binds
        end

        def call(next_arel)
          sql = next_arel.to_sql
          execute_sql.call(sql, binds)
        end
      end

      def initialize(internal_middleware = [], internal_context = {})
        @internal_middleware = internal_middleware
        @internal_context = internal_context
        @executing_middleware = false
      end

      def execute(sql, binds = [], &execute_sql)
        return execute_sql.call(sql, binds) if internal_middleware.length.zero?

        check_middleware_recursion(sql)
        @executing_middleware = true

        current_executor = SqlExecutor.new(execute_sql, binds)
        updated_context = context.merge(original_sql: sql)

        internal_middleware.reverse.each do |middleware|
          current_executor = MiddlewareExecutor
            .new(middleware, current_executor, updated_context.dup)
        end

        enhanced_arel = Arel.enhance(Arel.sql_to_arel(sql, binds: binds))
        result = current_executor.call(enhanced_arel)

        case result
        when PG::Result
          result
        when Array
          result
        else
          raise "Datatype returned from middleware `#{result.class}` should be a SQL result"
        end
      ensure
        @executing_middleware = false
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

      def check_middleware_recursion(sql)
        return unless executing_middleware

        message = <<~ERROR
          Middleware is being called from within middleware, aborting execution
          to prevent endless recursion. You can do the following if you want to execute SQL
          inside middleware:

            - Set middleware context before entering the middleware
            - Use `Arel.middleware.none { ... }` to temporarily disable middleware

          SQL that triggered the error:
          #{sql}
        ERROR

        raise message
      end
    end
  end
end
