module FFI
  class StringCaster
    extend FFI::DataConverter
    native_type :pointer

    class << self
      def to_native(value, struct, external_name, internal_name)
        pointer = case value
                  when nil
                    FFI::MemoryPointer::NULL
                  when String
                    FFI::MemoryPointer.from_string(value)
                  else
                    raise "`#{value}` (#{value.class}) should be a String"
                  end

        position = struct.offset_of(internal_name)
        struct.remember_pointer(pointer, external_name)
        struct.pointer.put_pointer(position, pointer)
      end

      #   # https://github.com/ffi/ffi/wiki/Pointers#fresh-strings
      #   # TODO: no clue if UTF-8 is the correct here
      #   self[:name].read_string.force_encoding('UTF-8')
      def from_native(struct, _external_name, internal_name)
        return if struct[internal_name].null?

        struct[internal_name].read_string
      end
    end
  end
end
