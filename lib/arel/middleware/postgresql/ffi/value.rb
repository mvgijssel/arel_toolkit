module Arel
  module Middleware
    module Postgresql
      module FFI
        # postgres/src/interfaces/libpq/libpq-int.h:135
        class Value < ::FFI::ExtendedStruct
          attribute :len, :int
          attribute :value, :pointer, ::FFI::StringCaster
        end
      end
    end
  end
end
