module Arel
  module Middleware
    class DatabaseExecutor
      attr_reader :middleware

      attr_accessor :index
      attr_reader :context
      attr_reader :final_block

      def initialize(middleware)
        @middleware = middleware
      end

      def run(arel, context, final_block)
        @index = 0
        @context = context
        @final_block = final_block

        enhanced_arel = Arel.enhance(arel)

        result = call(enhanced_arel)
        check_return_type result
        result
      ensure
        @index = 0
        @context = nil
        @final_block = nil
      end

      def call(next_arel)
        check_argument_type next_arel

        current_middleware = middleware[index]

        return execute_sql(next_arel) if current_middleware.nil?

        self.index += 1

        case current_middleware.method(:call).arity
        when 2
          current_middleware.call(next_arel, self)
        else
          current_middleware.call(next_arel, self, context.dup)
        end
      end

      private

      def execute_sql(next_arel)
        sql, binds = next_arel.to_sql_and_binds
        sql_result = final_block.call(sql, binds)
        check_return_type sql_result
        sql_result
      end

      def check_argument_type(next_arel)
        return if next_arel.is_a?(Arel::Enhance::Node)

        raise "Only `Arel::Enhance::Node` is valid for middleware, passed `#{next_arel.class}`"
      end

      def check_return_type(return_object)
        return if return_object.is_a?(Arel::Middleware::Result)

        raise 'Object returned from middleware needs to be wrapped in `Arel::Middleware::Result`' \
              " for object `#{return_object}`"
      end
    end
  end
end
