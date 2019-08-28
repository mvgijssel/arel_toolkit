module Arel
  module Middleware
    module Postgresql
      class Result
        class << self
          def columns(pg_result)
            pg_result.fields.each_with_index.map do |field, _index|
              Arel::Middleware::Column.new(field)
            end
          end

          def rows(pg_result)
            pg_result.values
          end

          def cast_to(result)
            if result.modified?
              # result.original_data.clear
              result.original_data
            else
              result.original_data
            end
          end
        end
      end

      class Result
        class Empty < Postgresql::Result
          class << self
            def cast_to(_result)
              # This will make an empty PG::Result object
              # with status PGRES_TUPLES_OK, which is the same
              # as any query returning data
              ActiveRecord::Base.connection.raw_connection.make_empty_pgresult(2)
            end
          end
        end
      end
    end
  end
end
