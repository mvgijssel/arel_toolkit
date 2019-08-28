module Arel
  module Middleware
    module Postgresql
      module Bridge
        # src/interfaces/libpq/libpq-fe.h:235
        class PGresAttDesc < FFI::Struct
          layout :name, :pointer,
                 :tableid, :oid,
                 :columnid, :int,
                 :format, :int,
                 :typid, :oid,
                 :typlen, :int,
                 :atttypmod, :int
        end

        class Column
          def initialize(
            name:,
            tableid:,
            columnid:,
            format:,
            typid:,
            typlen:,
            atttypmod:
          )
            @data = PGresAttDesc.new

            self.name = name
            data[:tableid] = tableid
            data[:columnid] = columnid
            data[:format] = format
            data[:typid] = typid
            data[:typlen] = typlen
            data[:atttypmod] = atttypmod
          end

          # copied setter from
          # https://github.com/Paxa/fast_excel/issues/30
          def name=(val)
            pos = data.offset_of(:name)

            if val.is_a?(String)
              val = FFI::MemoryPointer.from_string(val)
            end

            if val.nil?
              data.pointer.put_pointer(pos, FFI::MemoryPointer::NULL)
            elsif val.is_a?(FFI::MemoryPointer)
              data.pointer.put_pointer(pos, val)
            else
              raise("keywords= requires an FFI::MemoryPointer or nil")
            end

            val
          end

          def name
            # https://github.com/ffi/ffi/wiki/Pointers#fresh-strings
            # TODO: no clue if UTF-8 is the correct here
            self[:name].read_string.force_encoding('UTF-8')
          end

          private

          attr_reader :data
        end
      end
    end
  end
end
