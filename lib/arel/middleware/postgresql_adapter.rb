module Arel
  module Middleware
    module PostgreSQLAdapter
      def initialize(*args)
        Arel.middleware.none do
          super(*args)
        end
      end

      def execute(sql, name = nil)
        super(sql, name)
      end

      alias parent_execute execute

      # rubocop:disable Lint/DuplicateMethods
      def execute(sql, name = nil)
        Arel::Middleware.current_chain.execute(sql) do |processed_sql|
          Arel::Middleware::Result.create(
            data: parent_execute(processed_sql, name),
            from: Arel::Middleware::PGResult,
            to: Arel::Middleware::PGResult,
          )
        end
      end
      # rubocop:enable Lint/DuplicateMethods

      def query(sql, name = nil)
        Arel::Middleware.current_chain.execute(sql) do |processed_sql|
          # NOTE: we're not calling `super` here, but execute.
          # The `query` super does not return the columns, like the other methods.
          # As we want the result objects to be the same, we call execute instead.
          Arel::Middleware::Result.create(
            data: parent_execute(processed_sql, name),
            from: Arel::Middleware::PGResult,
            to: Arel::Middleware::ArrayResult,
          )
        end
      end

      def exec_no_cache(sql, name, binds, async: false)
        Arel::Middleware.current_chain.execute(sql, binds) do |processed_sql, processed_binds|
          Arel::Middleware::Result.create(
            data: super(processed_sql, name, processed_binds, async: async),
            from: Arel::Middleware::PGResult,
            to: Arel::Middleware::PGResult,
          )
        end
      end

      def exec_cache(sql, name, binds, async: false)
        Arel::Middleware.current_chain.execute(sql, binds) do |processed_sql, processed_binds|
          Arel::Middleware::Result.create(
            data: super(processed_sql, name, processed_binds, async: async),
            from: Arel::Middleware::PGResult,
            to: Arel::Middleware::PGResult,
          )
        end
      end
    end
  end
end
