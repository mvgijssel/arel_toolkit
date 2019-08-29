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
          attribute :tuples, :pointer,
                    caster: ::FFI::StructMultiArrayCaster.new(Postgresql::FFI::Value, :num_rows, :num_attributes),
                    as: :rows
        end
      end
    end
  end
end
