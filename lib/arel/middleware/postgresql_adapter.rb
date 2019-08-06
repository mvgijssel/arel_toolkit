module Arel
  module Middleware
    module PostgreSQLAdapter
      def initialize(*args)
        Arel.middleware.none do
          super(*args)
        end
      end

      def execute(sql, name = nil)
        Arel::Middleware.current_chain.execute(sql) do |processed_sql|
          super(processed_sql, name)
        end
      end

      def query(sql, name = nil)
        Arel::Middleware.current_chain.execute(sql) do |processed_sql|
          super(processed_sql, name)
        end
      end

      def exec_no_cache(sql, name, binds)
        Arel::Middleware.current_chain.execute(sql, binds) do |processed_sql, processed_binds|
          super(processed_sql, name, processed_binds)
        end
      end

      def exec_cache(sql, name, binds)
        Arel::Middleware.current_chain.execute(sql, binds) do |processed_sql, processed_binds|
          super(processed_sql, name, processed_binds)
        end
      end
    end
  end
end
