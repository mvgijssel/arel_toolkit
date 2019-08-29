module Arel
  module Middleware
    module Postgresql
      module FFI
        # postgres/src/interfaces/libpq/libpq-fe.h:235
        class Column < ::FFI::ExtendedStruct
          attribute :name, :pointer, caster: ::FFI::StringCaster
          attribute :tableid, :oid
          attribute :columnid, :int
          attribute :format, :int
          attribute :typid, :oid
          attribute :typlen, :int
          attribute :atttypmod, :int
        end
      end
    end
  end
end
