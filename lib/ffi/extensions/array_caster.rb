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

    def to_native(values, struct, external_name, internal_name)
      pointer = ::FFI::MemoryPointer.new(type, values.length)
      pointer.write_array_of(cast_type(type), cast_values(values))

      position = struct.internal.offset_of(internal_name)
      struct.internal.pointer.put_pointer(position, pointer)
      struct.remember_pointer(pointer, external_name)
    end

    def from_native(struct, _external_name, internal_name)
      # pointer = ::FFI::MemoryPointer.new(type, values.size)
      # pointer.write_array_of(type, array)
      # position = struct.internal.offset_of(internal_name)
      # struct.internal.pointer.put_pointer(position, pointer)
      # struct.remember_pointer(pointer, external_name)
      # type_size = 0


      # return [] if struct.internal[internal_name].null?

      val_array = ::FFI::Pointer.new(type, struct.internal[internal_name])
      val_array.read_array_of(type, struct.send(length_attribute))
    end

    private

    def find_type(type)
      type = if type.is_a?(Class) && type < ::FFI::ExtendedStruct
               ::FFI::Type::POINTER
             else
               type
             end

      FFI.find_type(type)
    end

    def cast_values(values)
      if type < ::FFI::ExtendedStruct
        values.map { |value| value.internal.pointer }
      else
        values
      end
    end

    def cast_type(type)
      if type < ::FFI::ExtendedStruct
      else
        type
      end
    end

    # def to_native(value, struct, external_name, internal_name)
    #   array_pointer = ::FFI::MemoryPointer.new(:pointer, value.length)

    #   value.each_with_index do |nested_items, index|
    #     nested_array_pointer = type.to_array_pointer(nested_items)

    #     array_pointer[index].put_pointer(0, nested_array_pointer)
    #   end

    #   position = struct.internal.offset_of(internal_name)
    #   struct.internal.pointer.put_pointer(position, array_pointer)
    #   struct.remember_pointer(array_pointer, external_name)
    # end

    # def from_native(struct, _external_name, internal_name)
    #   return [] if struct.internal[internal_name].null?

    #   pointer_array = ::FFI::Pointer.new(:pointer, struct.internal[internal_name])

    #   0.upto(struct.send(length_attribute) - 1).map do |index|
    #     pointer = pointer_array[index].read_pointer

    #     nested_pointer_array = ::FFI::Pointer.new(type, pointer)

    #     0.upto(struct.send(nested_length_attribute) - 1).map do |nested_index|
    #       type.from_pointer(nested_pointer_array[nested_index])
    #     end
    #   end
    # end
  end
end
