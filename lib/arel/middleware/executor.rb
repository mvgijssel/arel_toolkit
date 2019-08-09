module Arel
  module Middleware
    class Executor
      attr_reader :middleware

      attr_accessor :index
      attr_reader :context
      attr_reader :final_block

      def initialize(middleware)
        @middleware = middleware
      end

      def run(enhanced_arel, context, final_block)
        @index = 0
        @context = context
        @final_block = final_block

        call(enhanced_arel)
      ensure
        @index = 0
        @context = nil
        @final_block = nil
      end

      def call(next_arel)
        check_type next_arel

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
        final_block.call(sql, binds)
      end

      def connection
        Arel::Table.engine.connection
      end

      def check_type(next_arel)
        return if next_arel.is_a?(Arel::Enhance::Node)

        raise "Only `Arel::Enhance::Node` is valid for middleware, passed `#{next_arel.class}`"
      end
    end
  end
end
