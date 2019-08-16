# Make sure the gems are loaded before ArelToolkit
require 'postgres_ext' if Gem.loaded_specs.key?('postgres_ext')
require 'active_record_upsert' if Gem.loaded_specs.key?('active_record_upsert')
require 'pg_search' if Gem.loaded_specs.key?('pg_search')
require 'rails/railtie' if Gem.loaded_specs.key?('railties')
require 'arel'

require 'arel_toolkit/version'
require 'arel/extensions'
require 'arel/sql_to_arel'
require 'arel/middleware'
require 'arel/enhance'
require 'arel/transformer'

module ArelToolkit
end

require 'ffi'
require 'inline'

# header file is useful src/interfaces/libpq/libpq-fe.h
# docs about the library https://www.postgresql.org/docs/9.1/libpq-misc.html

# What we want to do here:
# instantiate a PGresult struct in C
# - use PQmakeEmptyPGresult()

# somehow get a VALUE object for pg_conn
# instantiate a PG::Result object in ruby
module Test
  extend FFI::Library

  # https://stackoverflow.com/questions/41516431/can-i-pass-a-ruby-object-pointer-to-a-ruby-ffi-callback
  def self.ruby_to_pointer(obj)
    address = obj.object_id << 1
    ::FFI::Pointer.new(:pointer, address)
  end

  # https://stackoverflow.com/questions/41516431/can-i-pass-a-ruby-object-pointer-to-a-ruby-ffi-callback
  def self.pointer_to_ruby(ffi_pointer)
    require 'fiddle'
    address = ffi_pointer.to_i
    fiddle = ::Fiddle::Pointer.new(address)
    fiddle.to_value
  end

  dir = Gem.loaded_specs.fetch('pg').stub.extension_dir
  file = 'pg_ext.bundle'
  path = File.join(dir, file)

  ffi_lib path

  # src/interfaces/libpq/libpq-fe.h:100
  ExecStatusType = enum(
    :PGRES_EMPTY_QUERY, 0,
    :PGRES_COMMAND_OK,
    :PGRES_TUPLES_OK,
    :PGRES_COPY_OUT,
    :PGRES_COPY_IN,
    :PGRES_BAD_RESPONSE,
    :PGRES_NONFATAL_ERROR,
    :PGRES_FATAL_ERROR,
    :PGRES_COPY_BOTH,
    :PGRES_SINGLE_TUPLE
  )

  typedef :pointer, :pg_result
  typedef :pointer, :pg_conn
  typedef :pointer, :rb_pgresult
  typedef :pointer, :rb_pgconn

  # https://www.postgresql.org/docs/9.1/libpq-misc.html
  # from postgres libpq library
  attach_function :pq_make_empty_pg_result, :PQmakeEmptyPGresult, [:pg_conn, ExecStatusType], :pg_result

  # from pg ruby
  attach_function :pg_new_result, [:pg_result, :rb_pgconn], :rb_pgresult

  def self.do_it
    pg_result_pointer = Test.pq_make_empty_pg_result(
      nil,
      Test::ExecStatusType[:PGRES_EMPTY_QUERY],
    )

    conn = ActiveRecord::Base.connection.raw_connection
    conn_pointer = Test.ruby_to_pointer(conn)

    Test.pg_new_result(pg_result_pointer, nil)
  end

  # Add C debugger to debug segmentation fault

  # https://github.com/banister/binding_of_caller/issues/57
  # def to_native(obj)
  #   id = obj.__id__
  #   case obj
  #   when Symbol                                  then FFI::Pointer.new id << 8 | 0xe
  #   when Fixnum, FalseClass, TrueClass, NilClass then FFI::Pointer.new id
  #   else                                                FFI::Pointer.new id << 1
  #   end
  # end

  # https://stackoverflow.com/questions/41516431/can-i-pass-a-ruby-object-pointer-to-a-ruby-ffi-callback

  # conn = ActiveRecord::Base.connection.raw_connection
  # Test.pg_new_result(pg_result_pointer, )



  # typedef :pointer, :pg_result
  # Lists all the type definitions available: FFI::TypeDefs
  # This is wrong, it's not a pointer but a VALUE object
  # typedef :pointer, :pg_conn

  # This is probably the method to instantiate a PG::Result
  # From the pg gem
  # attach_function :pg_new_result, [:pg_result, :pg_conn], :void

  # the definition of the PGresult or pg_result Struct in postgres/postgres
  # src/interfaces/libpq/libpq-int.h:167
  # class PGData < FFI::Struct
  #   layout :ntups, :int,
  #          :numAttributes, :int
  # end

  # data = PGData.new
  # data[:ntups] = 0
  # data[:numAttributes] = 0
  # data_pointer = data.pointer

  # Ruby object to C pointer and back to Ruby object using fiddle
  # https://stackoverflow.com/questions/41516431/can-i-pass-a-ruby-object-pointer-to-a-ruby-ffi-callback


  # pg_new_result(data_pointer, data_pointer)

  # get the PG connection
  # conn = ActiveRecord::Base.connection.raw_connection

  # attach_function :count, [:int, :float], :double
  # inline do |builder|
  #   builder.include '"pg.h"'
  # end
end

# Article going from C struct to Ruby and from Ruby to C struct
# http://clalance.blogspot.com/2013/11/writing-ruby-extensions-in-c-part-13.html

# You need to define allocate method which instantiates an actual Ruby object
# https://stackoverflow.com/questions/29720517/creating-c-structs-using-the-rubyinline-gem
dir = Gem.loaded_specs.fetch('pg').stub.extension_dir
file = 'pg_ext.bundle'
path = File.join(dir, file)

puts path


class Test2
  inline do |builder|
    builder.add_compile_flags '-lpg_ext'
    # builder.add_compile_flags '-I/Users/maarten/.anyenv/envs/rbenv/versions/2.5.3/lib/ruby/gems/2.5.0/gems/pg-1.1.4/ext'
    builder.include '<pg.h>'
  end
  # inline do |builder|
  #   builder.add_compile_flags '-I/Users/maarten/.anyenv/envs/rbenv/versions/2.5.3/lib/ruby/gems/2.5.0/gems/pg-1.1.4/ext'
  #   # builder.add_compile_flags ''
  #   # builder.add_link_flags %q(-lpg)
  #   builder.include '"pg.h"'
  #   # builder.include '"/Users/maarten/.anyenv/envs/rbenv/versions/2.5.3/lib/ruby/gems/2.5.0/gems/pg-1.1.4/ext/pg.h"'
  #   # builder.c '
  #   #   VALUE
  #   #   papi(VALUE ruby_pg_result) {
  #   #     PGresult *pointer_pg_result = pgresult_get(ruby_pg_result);
  #   #     return INT2FIX(PQntuples(*pointer_pg_result));

  #   #     // return pgresult_ntuples(ruby_pg_result);
	#   #    // return INT2FIX(PQresultStatus(ruby_pg_result));
  #   #    // rb_p(ruby_pg_result)
  #   #    // PQfnumber(res, "FOO");
  #   #   }
  #   # '
  # end

  def self.do_it
    ruby_pg_result = ActiveRecord::Base.connection.raw_connection.make_empty_pgresult(2)
    Test2.new.papi(ruby_pg_result)
  end
end
