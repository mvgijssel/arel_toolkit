module Arel
  module Middleware
    class Chain
      attr_reader :executing_middleware
      attr_reader :executor

      def initialize(internal_middleware = [], internal_context = {})
        @internal_middleware = internal_middleware
        @internal_context = internal_context
        @executor = Arel::Middleware::Executor.new(internal_middleware)
        @executing_middleware = false
      end

      def execute(sql, binds = [], &execute_sql)
        return execute_sql.call(sql, binds) if internal_middleware.length.zero?

        check_middleware_recursion(sql)

        updated_context = context.merge(original_sql: sql)
        enhanced_arel = Arel.enhance(Arel.sql_to_arel(sql, binds: binds))

        result = executor.run(enhanced_arel, updated_context, execute_sql)

        # TODO: pass this type in from the postgres adapter
        case result
        when PG::Result
          result
        when Array
          result
        else
          raise "Datatype returned from middleware `#{result.class}` should be a SQL result"
        end
      rescue ::PgQuery::ParseError
        execute_sql.call(sql, binds)
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
        if executing_middleware
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
        else
          @executing_middleware = true
        end
      end
    end
  end
end
