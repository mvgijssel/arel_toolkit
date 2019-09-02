module FFI
  class Pointer
    # copied from https://github.com/ffi/ffi/commit/c7afdbdd8fb79c50f9dd9dd0f8415bb29ce74668
    def read_array_of(type, size, length)
      Array.new(length) do |index|
        case type
        when ::FFI::StructByValue
          type.struct_class.new(self[index])
        when ::FFI::Type::Mapped
          get(type.type, index * size)
        else
          get(type, index * size)
        end
      end
    end

    def write_array_of(type, size, ary)
      ary.each_with_index do |value, index|
        case type
        when ::FFI::StructByValue
          value_bytes = value.pointer.get_bytes(0, size)
          self[index].put_bytes(0, value_bytes)
        when ::FFI::Type::Mapped
          put(type.type, index * size, value)
        else
          put(type, index * size, value)
        end
      end
      self
    end
  end
end
