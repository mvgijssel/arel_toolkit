module Arel
  module Middleware
    module Postgresql
      class Result
        class << self
          class Column < ::FFI::Struct
            layout :name, :pointer,
                   :tableid, :uint,
                   :columnid, :int,
                   :format, :int,
                   :typid, :uint,
                   :typlen, :int,
                   :atttypmod, :int
          end

          def columns(pg_result)
            pg_result.fields.each_with_index.map do |field, index|
              pg_result_object_address = pg_result.object_id << 1
              pg_result_pointer = FFI.pgresult_get(pg_result_object_address)

              Arel::Middleware::Column.new(
                field,
                tableid: FFI.pq_f_table(pg_result_pointer, index),
                columnid: FFI.pq_f_table_col(pg_result_pointer, index),
                format: FFI.pq_f_format(pg_result_pointer, index),
                typid: FFI.pq_f_type(pg_result_pointer, index),
                typlen: FFI.pq_f_size(pg_result_pointer, index),
                atttypmod: FFI.pq_f_mod(pg_result_pointer, index),
              )
            end
          end

          def rows(pg_result)
            pg_result.values
          end

          def cast_to(result)
            # return result.original_data unless result.modified?

            pg_result = do_it(result)

            # binding.pry

            pg_result
          end

          def do_it(result)
            # Instantiate an empty PG::Result
            pg_result = ActiveRecord::Base.connection.raw_connection.make_empty_pgresult(2)

            return pg_result if result.columns.length.zero?

            pg_columns_pointer = ::FFI::MemoryPointer.new(Column.size, result.columns.length)
            puts "PG_COLUMNS_POINTER: #{pg_columns_pointer}"
            # pg_columns_pointer.autorelease = false

            # Create and add the columns to the result object
            pg_columns = result.columns.each_with_index.map do |column, index|
              local_pointer = pg_columns_pointer.slice(Column.size * index, Column.size)
              # local_pointer = pg_columns_pointer[index]
              pg_column = Column.new(local_pointer)

              # binding.pry if result.columns.length > 1

              puts "STRUCT POINTER: #{local_pointer}"

              name_pointer = ::FFI::MemoryPointer.from_string(column.name)

              pg_column[:name] = name_pointer
              pg_column[:tableid] = column.metadata.fetch(:tableid)
              pg_column[:columnid] = column.metadata.fetch(:columnid)
              pg_column[:format] = column.metadata.fetch(:format)
              pg_column[:typid] = column.metadata.fetch(:typid)
              pg_column[:typlen] = column.metadata.fetch(:typlen)
              pg_column[:atttypmod] = column.metadata.fetch(:atttypmod)
              pg_column

              {
                local_pointer: local_pointer,
                name_pointer: name_pointer,
              }
            end

            # pg_columns_pointer = ::FFI::MemoryPointer.new(:pointer, pg_columns.length)
            # pg_columns_pointer.autorelease = false

            # pg_columns.each_with_index do |pg_column, index|
            #   # value_bytes = pg_column.pointer.get_bytes(0, Column.size)
            #   # pg_columns_pointer[index].put_bytes(0, value_bytes)
            #   pg_columns_pointer[index].write_pointer(pg_column.pointer)
            # end

            pg_result_object_address = pg_result.object_id << 1
            pg_result_pointer = FFI.pgresult_get(pg_result_object_address)

            puts "RESULT POINTER: #{pg_result_pointer}"

            # pg_result_pointer.autorelease = false # which is the default


            FFI.pq_set_result_attrs pg_result_pointer, result.columns.length, pg_columns_pointer

            pg_columns.each do |pg_column|
              # pg_column.pointer.free
              # pg_column[:local_pointer].free
              pg_column[:name_pointer].free
            end

            pg_columns_pointer.free

            # pg_columns_pointer.free

            # pg_columns_pointer.free
            # pg_columns.each { |pg_column| pg_column.pointer.free }


            # Add the rows to the result object
            # result.rows.each_with_index do |row, row_index|
            #   row.each_with_index do |value, column_index|
            #     value_string = value.to_s
            #     value_pointer = ::FFI::MemoryPointer.from_string(value_string)
            #     value_pointer.autorelease = false

            #     FFI.pq_set_value(
            #       pg_result_pointer,
            #       row_index,
            #       column_index,
            #       value_pointer,
            #       value_string.length,
            #     )
            #   end
            # end

            # binding.pry

            pg_result
          end

          private

          def new_column(column)
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
