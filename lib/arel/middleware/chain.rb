require_relative './no_op_cache'
require_relative './cache_accessor'

module Arel
  module Middleware
    class Chain
      attr_reader :executing_middleware_depth, :executor, :cache

      MAX_RECURSION_DEPTH = 10

      def initialize(
        internal_middleware = [],
        internal_context = {},
        executor_class = Arel::Middleware::DatabaseExecutor,
        cache: nil
      )
        @internal_middleware = internal_middleware
        @internal_context = internal_context
        @executor = executor_class.new(internal_middleware)
        @executing_middleware_depth = 0
        @cache = cache || NoOpCache
      end

      def cache_accessor
        @cache_accessor ||= CacheAccessor.new @cache
      end

      def execute(sql, binds = [], &execute_sql)
        return execute_sql.call(sql, binds).to_casted_result if internal_middleware.length.zero?

        if (cached_sql = cache_accessor.read(sql))
          return execute_sql.call(cached_sql, binds).to_casted_result
        end

        execute_with_middleware(sql, binds, execute_sql).to_casted_result
      rescue ::PgQuery::ParseError
        execute_sql.call(sql, binds)
      ensure
        @executing_middleware_depth -= 1
      end

      def current
        internal_middleware.dup
      end

      def apply(middleware, cache: @cache, &block)
        new_middleware = Array.wrap(middleware)
        continue_chain(new_middleware, internal_context, cache: cache, &block)
      end
      alias only apply

      def none(&block)
        continue_chain([], internal_context, cache: cache, &block)
      end

      def except(without_middleware, cache: @cache, &block)
        without_middleware = Array.wrap(without_middleware)
        new_middleware = internal_middleware - without_middleware
        continue_chain(new_middleware, internal_context, cache: cache, &block)
      end

      def insert_before(new_middleware, existing_middleware, cache: @cache, &block)
        new_middleware = Array.wrap(new_middleware)
        index = internal_middleware.index(existing_middleware)
        updated_middleware = internal_middleware.insert(index, *new_middleware)
        continue_chain(updated_middleware, internal_context, cache: cache, &block)
      end

      def prepend(new_middleware, cache: @cache, &block)
        new_middleware = Array.wrap(new_middleware)
        updated_middleware = new_middleware + internal_middleware
        continue_chain(updated_middleware, internal_context, cache: cache, &block)
      end

      def insert_after(new_middleware, existing_middleware, cache: @cache, &block)
        new_middleware = Array.wrap(new_middleware)
        index = internal_middleware.index(existing_middleware)
        updated_middleware = internal_middleware.insert(index + 1, *new_middleware)
        continue_chain(updated_middleware, internal_context, cache: cache, &block)
      end

      def append(new_middleware, cache: @cache, &block)
        new_middleware = Array.wrap(new_middleware)
        updated_middleware = internal_middleware + new_middleware
        continue_chain(updated_middleware, internal_context, cache: cache, &block)
      end

      def context(new_context = nil, &block)
        if new_context.nil? && !block.nil?
          raise 'You cannot do a block statement while calling context without arguments'
        end

        return internal_context if new_context.nil?

        continue_chain(internal_middleware, new_context, cache: @cache, &block)
      end

      def to_sql(type, &block)
        middleware = Arel::Middleware::ToSqlMiddleware.new(type)

        new_chain = Arel::Middleware::Chain.new(
          internal_middleware + [middleware],
          internal_context,
          Arel::Middleware::ToSqlExecutor,
        )

        maybe_execute_block(new_chain, &block)

        middleware.sql
      end

      protected

      attr_reader :internal_middleware, :internal_context

      private

      def enhance_arel(sql, binds)
        Arel.enhance(Arel.sql_to_arel(sql, binds: binds))
      end

      def execute_with_middleware(sql, binds, execute_sql)
        check_middleware_recursion(sql)

        updated_context = context.merge(
          original_sql: sql,
          original_binds: binds,
          cache_accessor: cache_accessor,
        )

        enhanced_arel = enhance_arel(arel)

        executor.run(enhanced_arel, updated_context, execute_sql)
      end

      def continue_chain(middleware, context, cache:, &block)
        new_chain = Arel::Middleware::Chain.new(middleware, context, cache: cache)
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
        if executing_middleware_depth > MAX_RECURSION_DEPTH
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
          @executing_middleware_depth += 1
        end
      end
    end
  end
end
