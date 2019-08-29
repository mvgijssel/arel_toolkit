module FFI
  class StringCaster
    class << self
      # handle nil
      def to_native(value, struct, attribute_name)
        pointer = case value
                  when nil
                    FFI::MemoryPointer::NULL
                  when String
                    FFI::MemoryPointer.from_string(value)
                  else
                    raise "`#{value}` (#{value.class}) should be a String"
                  end

        position = struct.internal.offset_of(attribute_name)
        struct.remember_pointer(pointer, attribute_name)
        struct.internal.pointer.put_pointer(position, pointer)
      end

      def from_native(struct, attribute_name)
        return if struct.internal[attribute_name].null?

        struct.internal[attribute_name].read_string

        #   # https://github.com/ffi/ffi/wiki/Pointers#fresh-strings
        #   # TODO: no clue if UTF-8 is the correct here
        #   self[:name].read_string.force_encoding('UTF-8')
      end
    end
  end
end
