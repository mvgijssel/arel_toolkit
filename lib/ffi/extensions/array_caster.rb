module FFI
  # # https://zegoggl.es/2009/05/ruby-ffi-recipes.html
  class ArrayCaster
    include FFI::DataConverter
    def native_type
      FFI::Type::POINTER
    end

    attr_reader :type, :length_attribute

    def initialize(type, length_attribute)
      @type = type
      @length_attribute = length_attribute
    end

    # TODO: handle nil
    def to_native(values, struct, external_name, internal_name)
      builtin_type = find_type(struct)
      type_size = type_size(builtin_type)

      pointer = ::FFI::MemoryPointer.new(type_size, values.length)
      pointer.write_array_of(builtin_type, type_size, values)

      position = struct.offset_of(internal_name)
      struct.pointer.put_pointer(position, pointer)
      struct.remember_pointer(pointer, external_name)
    end

    def from_native(struct, _external_name, internal_name)
      return [] if struct[internal_name].null?

      builtin_type = find_type(struct)
      type_size = type_size(builtin_type)
      pointer = ::FFI::Pointer.new(type_size, struct[internal_name])
      pointer.read_array_of(builtin_type, type_size, struct.send(length_attribute))
    end

    private

    def find_type(struct)
      struct.class.send(:find_type, type, struct.class.send(:enclosing_module))
    end

    def type_size(builtin_type)
      builtin_type.size
    end
  end
end
