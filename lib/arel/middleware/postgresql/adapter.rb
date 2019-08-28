module Arel
  module Middleware
    module Postgresql
      module Adapter
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
              from: Postgresql::Result,
              to: Postgresql::Result,
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
              from: Postgresql::Result,
              to: Arel::Middleware::Result::Array,
            )
          end
        end

        def exec_no_cache(sql, name, binds)
          Arel::Middleware.current_chain.execute(sql, binds) do |processed_sql, processed_binds|
            Arel::Middleware::Result.create(
              data: super(processed_sql, name, processed_binds),
              from: Postgresql::Result,
              to: Postgresql::Result,
            )
          end
        end

        def exec_cache(sql, name, binds)
          Arel::Middleware.current_chain.execute(sql, binds) do |processed_sql, processed_binds|
            Arel::Middleware::Result.create(
              data: super(processed_sql, name, processed_binds),
              from: Postgresql::Result,
              to: Postgresql::Result,
            )
          end
        end

        def sql_without_execution(sql)
          Arel::Middleware::Result.create(
            data: sql,
            from: Arel::Middleware::Result::String,
            to: Postgresql::Result::Empty,
          )
        end
      end
    end
  end
end
