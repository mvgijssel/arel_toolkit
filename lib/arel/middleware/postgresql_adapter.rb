module Arel
  module Middleware
    module PostgreSQLAdapter
      def initialize(*args)
        Arel.middleware.none do
          super(*args)
        end
      end

      def execute(sql, name = nil)
        sql = Arel::Middleware.current_chain.execute(sql)
        super(sql, name)
      end

      def exec_no_cache(sql, name, binds)
        sql = Arel::Middleware.current_chain.execute(sql, binds)
        super(sql, name, binds)
      end

      def exec_cache(sql, name, binds)
        sql = Arel::Middleware.current_chain.execute(sql, binds)
        super(sql, name, binds)
      end

      def query(sql, name)
        sql = Arel::Middleware.current_chain.execute(sql)
        super(sql, name)
      end
    end
  end
end
