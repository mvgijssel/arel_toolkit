# typed: false
module Arel
  module Middleware
    module PostgreSQLAdapter
      sig { params(args: T::Array[T::Hash[Symbol, String]]).void }
      def initialize(*args)
        Arel.middleware.none do
          super(*args)
        end
      end

      sig { params(sql: String, name: String).returns(PG::Result) }
      def execute(sql, name = nil)
        sql = Arel::Middleware.current_chain.execute(sql)
        super(sql, name)
      end

      sig { params(sql: String, name: String, binds: T::Array[ActiveRecord::Relation::QueryAttribute]).returns(PG::Result) }
      def exec_no_cache(sql, name, binds)
        sql = Arel::Middleware.current_chain.execute(sql, binds)
        super(sql, name, binds)
      end

      sig { params(sql: String, name: String, binds: T::Array[ActiveRecord::Relation::QueryAttribute]).returns(PG::Result) }
      def exec_cache(sql, name, binds)
        sql = Arel::Middleware.current_chain.execute(sql, binds)
        super(sql, name, binds)
      end
    end
  end
end