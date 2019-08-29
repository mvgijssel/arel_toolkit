module Arel
  module Middleware
    module Postgresql
      class Result
        class << self
          def columns(pg_result)
            pg_result.fields.each_with_index.map do |field, index|
              Arel::Middleware::Column.new(
                field,
                name: Postgresql::FFI.result_column_name(pg_result, index),
                tableid: Postgresql::FFI.result_column_table_id(pg_result, index),
                columnid: Postgresql::FFI.result_column_id(pg_result, index),
                format: Postgresql::FFI.result_column_format(pg_result, index),
                typid: Postgresql::FFI.result_column_type_id(pg_result, index),
                typlen: Postgresql::FFI.result_column_type_length(pg_result, index),
                atttypmod: Postgresql::FFI.result_column_type_modifier(pg_result, index),
              )
            end
          end

          def rows(pg_result)
            pg_result.values
          end

          def cast_to(result)
            return result.original_data unless result.modified?

            # Instantiate an empty PG::Result
            pg_result = Postgresql::FFI.new_result

            # Create and add the columns to the result object
            pg_columns = result.columns.map do |column|
              Postgresql::FFI.new_column(
                name: column.name,
                tableid: column.metadata.fetch(:tableid),
                columnid: column.metadata.fetch(:columnid),
                format: column.metadata.fetch(:format),
                typid: column.metadata.fetch(:typid),
                typlen: column.metadata.fetch(:typlen),
                atttypmod: column.metadata.fetch(:atttypmod),
              )
            end

            Postgresql::FFI.result_set_columns(pg_result, pg_columns)

            # Add the rows to the result object
            result.rows.each_with_index do |row, row_index|
              row.each_with_index do |value, column_index|
                Postgresql::FFI.result_set_value(pg_result, row_index, column_index, value)
              end
            end

            binding.pry

            pg_result
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
