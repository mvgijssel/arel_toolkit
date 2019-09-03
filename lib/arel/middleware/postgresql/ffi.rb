module Arel
  module Middleware
    module Postgresql
      module FFI
        extend ::FFI::Library
        dir = Gem.loaded_specs.fetch('pg').stub.extension_dir
        file = 'pg_ext.bundle'
        path = File.join(dir, file)
        ffi_lib path

        # postgres/src/include/postgres_ext.h:31
        typedef :uint, :oid

        typedef :ulong, :self
        typedef :pointer, :pg_result
        typedef :int, :column_number
        typedef :pointer, :att_descs
        typedef :pointer, :value
        typedef :int, :numAttributes
        typedef :int, :tup_num
        typedef :int, :field_num
        typedef :int, :len

        # ruby-pg/ext/pg_result.c:358
        attach_function :pgresult_get, [:self], :pg_result

        # https://www.postgresql.org/docs/10/libpq-exec.html
        attach_function :pq_f_name, :PQfname, %i[pg_result column_number], :pointer
        attach_function :pq_f_table, :PQftable, %i[pg_result column_number], :oid
        attach_function :pq_f_table_col, :PQftablecol, %i[pg_result column_number], :int
        attach_function :pq_f_format, :PQfformat, %i[pg_result column_number], :int
        attach_function :pq_f_type, :PQftype, %i[pg_result column_number], :oid
        attach_function :pq_f_size, :PQfsize, %i[pg_result column_number], :int
        attach_function :pq_f_mod, :PQfmod, %i[pg_result column_number], :int

        # https://www.postgresql.org/docs/10/libpq-misc.html
        attach_function :pq_set_result_attrs,
                        :PQsetResultAttrs,
                        %i[pg_result numAttributes att_descs],
                        :int
        attach_function :pq_set_value, :PQsetvalue, %i[pg_result tup_num field_num value len], :int

        class << self
          def new_result
            ActiveRecord::Base.connection.raw_connection.make_empty_pgresult(2)
          end

          def new_column(**kwargs)
            Postgresql::FFI::Column.from_data kwargs
          end

          def result_get_column(pg_result, column_name, index)
            pointer = pg_result_pointer(pg_result)

            Arel::Middleware::Column.new(
              column_name,
              name: pq_f_name(pointer, index),
              tableid: pq_f_table(pointer, index),
              columnid: pq_f_table_col(pointer, index),
              format: pq_f_format(pointer, index),
              typid: pq_f_type(pointer, index),
              typlen: pq_f_size(pointer, index),
              atttypmod: pq_f_mod(pointer, index),
            )
          end

          def result_struct(pg_result)
            Postgresql::FFI::Result.from_pointer pg_result_pointer(pg_result)
          end

          def result_set_columns(pg_result, pg_columns)
            pg_columns_pointer = ::FFI::MemoryPointer.new(
              Postgresql::FFI::Column,
              pg_columns.length,
            )

            pg_columns_pointer.write_array_of(
              Postgresql::FFI::Column.by_value,
              Postgresql::FFI::Column.size,
              pg_columns,
            )

            pq_set_result_attrs pg_result_pointer(pg_result), pg_columns.length, pg_columns_pointer
          end

          def result_set_value(pg_result, row_index, column_index, value)
            value_string = value.to_s
            value_pointer = ::FFI::MemoryPointer.from_string(value_string)

            pq_set_value(
              pg_result_pointer(pg_result),
              row_index,
              column_index,
              value_pointer,
              value_string.length,
            )
          end

          private

          def object_address(obj)
            obj.object_id << 1
          end

          def pg_result_pointer(pg_result)
            pgresult_get(object_address(pg_result))
          end
        end
      end
    end
  end
end
