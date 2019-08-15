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

# What we want to do here:
# instantiate a PGresult struct in C
# somehow get a VALUE object for pg_conn
# instantiate a PG::Result object in ruby
module Test
  extend FFI::Library

  dir = Gem.loaded_specs.fetch('pg').stub.extension_dir
  file = 'pg_ext.bundle'
  path = File.join(dir, file)

  ffi_lib path

  typedef :pointer, :pg_result
  # Lists all the type definitions available: FFI::TypeDefs
  # This is wrong, it's not a pointer but a VALUE object
  typedef :pointer, :pg_conn

  # This is probably the method to instantiate a PG::Result
  # From the pg gem
  attach_function :pg_new_result, [:pg_result, :pg_conn], :void

  # the definition of the PGresult or pg_result Struct in postgres/postgres
  # src/interfaces/libpq/libpq-int.h:167
  class PGData < FFI::Struct
    layout :ntups, :int,
           :numAttributes, :int
  end

  data = PGData.new
  data[:ntups] = 0
  data[:numAttributes] = 0
  data_pointer = data.pointer

  # Ruby object to C pointer and back to Ruby object using fiddle
  # https://stackoverflow.com/questions/41516431/can-i-pass-a-ruby-object-pointer-to-a-ruby-ffi-callback


  # pg_new_result(data_pointer, data_pointer)

  # get the PG connection
  # conn = ActiveRecord::Base.connection.raw_connection

  # attach_function :count, [:int, :float], :double
end
