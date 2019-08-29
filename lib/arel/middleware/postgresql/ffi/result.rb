module Arel
  module Middleware
    module Postgresql
      module FFI
        # postgres/src/interfaces/libpq/libpq-int.h:167
        class Result < ::FFI::ExtendedStruct
          attribute :ntups, :int, as: :num_rows
          attribute :numAttributes, :int, as: :num_attributes
          attribute :attDescs, :pointer,
                    caster: ::FFI::StructArrayCaster.new(Postgresql::FFI::Column, :num_attributes),
                    as: :attributes
          attribute :tuples, :pointer, as: :rows

          # # https://zegoggl.es/2009/05/ruby-ffi-recipes.html
          # # tuples are stored in a multi dimensional array, pointers of pointers
          # def values
          #   tuple_pointers = ::FFI::Pointer.new(:pointer, self[:tuples])

          #   0.upto(self[:ntups] - 1).map do |tuple_index|
          #     tuple_pointer = tuple_pointers[tuple_index].read_pointer

          #     column_pointer = ::FFI::Pointer.new(Postgresql::FFI::PGresAttValue, tuple_pointer)

          #     0.upto(self[:numAttributes] - 1).map do |column_index|
          #       Postgresql::FFI::PGresAttValue.new(column_pointer[column_index])
          #     end
          #   end
          # end
        end
      end
    end
  end
end
