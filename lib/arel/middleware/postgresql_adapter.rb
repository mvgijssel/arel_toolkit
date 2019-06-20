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

          alias_method :exec_no_cache_without_arel_middleware, :exec_no_cache
          def exec_no_cache(sql, name, binds)
            sql = Arel::Middleware.current_chain.execute(sql, binds)
            exec_no_cache_without_arel_middleware(sql, name, binds)
          end

          alias_method :exec_cache_without_arel_middleware, :exec_cache
          def exec_cache(sql, name, binds)
            sql = Arel::Middleware.current_chain.execute(sql, binds)
            exec_cache_without_arel_middleware(sql, name, binds)
          end
        end
      end
    end
  end
end
