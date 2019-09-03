module Arel
  module Middleware
    module Postgresql
      module FFI
        extend ::FFI::Library
        dir = Gem.loaded_specs.fetch('pg').stub.extension_dir
        file = ::FFI::Platform.mac? ? "pg_ext.bundle" : "pg_ext.so"
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
      end
    end
  end
end
