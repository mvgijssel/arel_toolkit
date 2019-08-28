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
  # Great article:
  # https://medium.com/@astantona/fiddling-with-rubys-fiddle-39f991dd0565
  extend FFI::Library

  dir = Gem.loaded_specs.fetch('pg').stub.extension_dir
  file = 'pg_ext.bundle'
  path = File.join(dir, file)

  ffi_lib path

  typedef :ulong, :self
  typedef :pointer, :pg_result

  attach_function :pgresult_get, [:self], :pg_result

  # https://www.postgresql.org/docs/10/libpq-misc.html
  # typedef :string, :value
  attach_function :pq_set_value, :PQsetvalue, [:pg_result, :int, :int, :pointer, :int], :int

  # Maybe use PQcopyResult to make a copy of an existing result object
  # pass proper flags to not copy the attributes and tuples
  # next set the attributes and tuples
  def self.test2
    result = ActiveRecord::Base.connection.raw_connection.make_empty_pgresult(2)
    result_pointer = Test.ruby_to_pointer(result)
    pg_result_pointer = Test.pgresult_get(result_pointer)
    Test.pq_set_value(pg_result_pointer, 0, 0, 'papi', 0)
  end

  typedef :pointer, :att_descs
  attach_function :pq_set_result_attrs, :PQsetResultAttrs, [:pg_result, :int, :att_descs], :int

  # src/include/postgres_ext.h:31
  # typedef unsigned int Oid;
  typedef :uint, :oid

  # src/interfaces/libpq/libpq-int.h:135
  class PGresAttValue < FFI::Struct
    layout :len, :int, # length in bytes of the value
           :value, :pointer # actual value, plus terminating zero byte

    def value=(val)
      pos = offset_of(:value)

      if val.is_a?(String)
        val = FFI::MemoryPointer.from_string(val)
      end

      if val.nil?
        pointer.put_pointer(pos, FFI::MemoryPointer::NULL)
      elsif val.is_a?(FFI::MemoryPointer)
        pointer.put_pointer(pos, val)
      else
        raise("keywords= requires an FFI::MemoryPointer or nil")
      end

      val
    end

    def value
      self[:value].read_string
    end
  end

  # src/interfaces/libpq/libpq-fe.h:235
  class PGresAttDesc < FFI::Struct
    layout :name, :pointer,
           :tableid, :oid,
           :columnid, :int,
           :format, :int,
           :typid, :oid,
           :typlen, :int,
           :atttypmod, :int

    # Scary. Ruby strings to C String pointer is hard apparently.
    # Can't simply do
    # layout :name, :string
    # and try to assign to that string, will result in "Cannot set string field"
    # because this is not a safe operation.

    # Can use a macro https://stackoverflow.com/questions/50917280/ruby-ffi-string-not-getting-to-char-function-argument
    # to safe convert a ruby string into a c string
    # which can then be used as a column name?

    # Maybe use the approach at https://github.com/ffi/ffi/wiki/Pointers

    # copied setter from
    # https://github.com/Paxa/fast_excel/issues/30
    def name=(val)
      pos = offset_of(:name)

      if val.is_a?(String)
        val = FFI::MemoryPointer.from_string(val)
      end

      if val.nil?
        pointer.put_pointer(pos, FFI::MemoryPointer::NULL)
      elsif val.is_a?(FFI::MemoryPointer)
        pointer.put_pointer(pos, val)
      else
        raise("keywords= requires an FFI::MemoryPointer or nil")
      end

      val
    end

    def name
      self[:name].read_string
    end

    def to_h
      result = {}

      members.each do |member|
        result[member] = self[member]
      end

      result
    end
  end

  # For query `SELECT 1 as kerk`
  # name => 'kerk'
  # tableid => 0
  # columnid => 0
  # format => 0
  # typid => 23
  # typlen => 4

  # src/interfaces/libpq/libpq-int.h:167
  class PGData < FFI::Struct
    layout :ntups, :int,
           :numAttributes, :int,
           :attDescs, :pointer,
           :tuples, :pointer

    def attributes
      val_array = FFI::Pointer.new(Test::PGresAttDesc, self[:attDescs])

      0.upto(self[:numAttributes] - 1).map do |i|
        Test::PGresAttDesc.new(val_array[i])
      end
    end

    # https://zegoggl.es/2009/05/ruby-ffi-recipes.html
    # tuples are stored in a multi dimensional array, pointers of pointers
    def values
      tuple_pointers = FFI::Pointer.new(:pointer, self[:tuples])

      0.upto(self[:ntups] - 1).map do |tuple_index|
        tuple_pointer = tuple_pointers[tuple_index].read_pointer

        column_pointer = FFI::Pointer.new(Test::PGresAttValue, tuple_pointer)

        0.upto(self[:numAttributes] - 1).map do |column_index|
          Test::PGresAttValue.new(column_pointer[column_index])
        end
      end
    end
  end


  attach_function :pq_f_size, :PQfsize, [:pg_result, :int], :int

  def self.test4
    result = ActiveRecord::Base.connection.execute("SELECT 1 AS kerk, 'papi' AS shine")
    result_pointer = Test.ruby_to_pointer(result)
    pg_result_pointer = Test.pgresult_get(result_pointer)

    puts Test.pq_f_size(pg_result_pointer, 0)
    puts Test.pq_f_size(pg_result_pointer, 1)

    # 1. create an empty result object / copy existing one without tuples
    # 2. create all the columns based on original result
    #    - use existing methods, like PQftable, PQftablecol, PQfformat, PQftype, PQfmod, PQfsize
    # 3. create all the tuples based on original result
  end

  def self.test3
    result = ActiveRecord::Base.connection.execute("SELECT 1 AS kerk")
    # result = ActiveRecord::Base.connection.raw_connection.make_empty_pgresult(2)
    result_pointer = Test.ruby_to_pointer(result)
    pg_result_pointer = Test.pgresult_get(result_pointer)

    # column = Test::PGresAttDesc.new
    # column.name = 'kerk'
    # column[:tableid] = 0
    # column[:columnid] = 0
    # column[:format] = 0
    # column[:typid] = 23
    # column[:typlen] = 4

    # Test.pq_set_result_attrs(pg_result_pointer, 1, column.pointer)

    # char_pointer = FFI::MemoryPointer.from_string('1')
    # Test.pq_set_value(pg_result_pointer, 0, 0, char_pointer, char_pointer.size)

    r = Test::PGData.new(pg_result_pointer)

    puts "Number of bytes: ", r.values.first.first[:len]

    # result.each { |node| puts node }

    # r.values.first.first.value = '2' # <-- change the 1 value to 2

    # result.each { |node| puts node }

    binding.pry

    # att_desc = Test::PGresAttDesc.new
    # att_desc[:name] = 'test'
  end

  # Instead of duplicating the struct here, modify the struct using public methods
  # https://www.postgresql.org/docs/10/libpq-misc.html
  # PQsetResultAttrs
  # PQsetvalue
  # PQmakeEmptyPGresult modifies all the necessary attributes
  # src/interfaces/libpq/fe-exec.c:142

  # https://stackoverflow.com/questions/41516431/can-i-pass-a-ruby-object-pointer-to-a-ruby-ffi-callback
  def self.ruby_to_pointer(obj)
    # obj.object_id << 1 # <<-- get the memory address, don't make it a pointer
    # https://stackoverflow.com/questions/2818602/in-ruby-why-does-inspect-print-out-some-kind-of-object-id-which-is-different/2818916#2818916
    # Read the article why this works
    address = obj.object_id << 1
    # ffi_pointer = ::FFI::Pointer.new(:pointer, address)
  end

  def self.test1
    # result = ActiveRecord::Base.connection.raw_connection.make_empty_pgresult(2)
    result = ActiveRecord::Base.connection.execute('SELECT 1')
    result_pointer = Test.ruby_to_pointer(result)
    pg_result_pointer = Test.pgresult_get(result_pointer)
    pg_data = Test::PGData.new(pg_result_pointer)

    puts result.ntuples

    binding.pry

    # pg_data[:ntups] = 10

    puts result.ntuples
  end
end

# Article going from C struct to Ruby and from Ruby to C struct
# http://clalance.blogspot.com/2013/11/writing-ruby-extensions-in-c-part-13.html
