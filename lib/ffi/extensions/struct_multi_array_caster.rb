module FFI
  # # https://zegoggl.es/2009/05/ruby-ffi-recipes.html
  class StructMultiArrayCaster < StructArrayCaster
    attr_reader :nested_length_attribute

    def initialize(type, length_attribute, nested_length_attribute)
      super(type, length_attribute)
      @nested_length_attribute = nested_length_attribute
    end

    def to_native(value, struct, external_name, internal_name)
      array_pointer = ::FFI::MemoryPointer.new(:pointer, value.length)

      value.each_with_index do |nested_items, index|
        nested_array_pointer = type.to_array_pointer(nested_items)

        array_pointer[index].put_pointer(0, nested_array_pointer)
      end

      position = struct.internal.offset_of(internal_name)
      struct.internal.pointer.put_pointer(position, array_pointer)
      struct.remember_pointer(array_pointer, external_name)
    end

    def from_native(struct, _external_name, internal_name)
      return [] if struct.internal[internal_name].null?

      pointer_array = ::FFI::Pointer.new(:pointer, struct.internal[internal_name])

      0.upto(struct.send(length_attribute) - 1).map do |index|
        pointer = pointer_array[index].read_pointer

        nested_pointer_array = ::FFI::Pointer.new(type, pointer)

        0.upto(struct.send(nested_length_attribute) - 1).map do |nested_index|
          type.from_pointer(nested_pointer_array[nested_index])
        end
      end
    end
  end
end
