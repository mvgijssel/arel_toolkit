module Arel
  module Middleware
    class Executor
      attr_reader :middleware

      attr_accessor :index
      attr_reader :context
      attr_reader :final_block
      attr_reader :binds

      def initialize(middleware)
        @middleware = middleware
      end

      def run(enhanced_arel, context, final_block, binds)
        @index = 0
        @context = context
        @final_block = final_block
        @binds = binds

        call(enhanced_arel)
      ensure
        @index = 0
        @context = nil
        @final_block = nil
        @binds = nil
      end

      def call(next_arel)
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
        sql = next_arel.to_sql
        final_block.call(sql, binds)
      end
    end
  end
end
