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

  # # https://stackoverflow.com/questions/41516431/can-i-pass-a-ruby-object-pointer-to-a-ruby-ffi-callback
  # def self.pointer_to_ruby(ffi_pointer)
  #   require 'fiddle'
  #   address = ffi_pointer.to_i
  #   fiddle = ::Fiddle::Pointer.new(address)
  #   fiddle.to_value
  # end

  dir = Gem.loaded_specs.fetch('pg').stub.extension_dir
  file = 'pg_ext.bundle'
  path = File.join(dir, file)

  ffi_lib path

  typedef :ulong, :self # <<-- look, just unsigned long!
  typedef :pointer, :pg_result

  attach_function :pgresult_get, [:self], :pg_result

  class PGData < FFI::Struct
    layout :ntups, :int,
           :numAttributes, :int
  end

  # https://stackoverflow.com/questions/41516431/can-i-pass-a-ruby-object-pointer-to-a-ruby-ffi-callback
  def self.ruby_to_pointer(obj)
    obj.object_id << 1 # <<-- get the memory address, don't make it a pointer
  end

  def self.do_it
    # result = ActiveRecord::Base.connection.raw_connection.make_empty_pgresult(2)
    result = ActiveRecord::Base.connection.execute('SELECT 1')
    result_pointer = Test.ruby_to_pointer(result)
    pg_result_pointer = Test.pgresult_get(result_pointer)
    pg_data = Test::PGData.new(pg_result_pointer)

    puts result.ntuples

    pg_data[:ntups] = 10

    puts result.ntuples
  end
end

# Article going from C struct to Ruby and from Ruby to C struct
# http://clalance.blogspot.com/2013/11/writing-ruby-extensions-in-c-part-13.html
