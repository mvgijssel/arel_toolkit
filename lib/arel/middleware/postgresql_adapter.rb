module Arel
  module Middleware
    module PostgreSQLAdapter
      def self.included(instrumented_class)
        instrumented_class.class_eval do
          alias_method :execute_without_arel_middleware, :execute
          def execute(sql, name = nil)
            sql = Arel::Middleware.current_chain.execute(sql)
            execute_without_arel_middleware(sql, name)
          end

          alias_method :execute_and_clear_without_arel_middleware, :execute_and_clear
          def execute_and_clear(sql, name, binds, prepare: false, &block)
            binding.pry
            sql = Arel::Middleware.current_chain.execute(sql)
            execute_and_clear_without_arel_middleware(sql, name, binds, prepare: prepare, &block)
          end
        end
      end
    end
  end
end
