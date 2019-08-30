module FFI
  class StructArrayCaster
    attr_reader :type, :length_attribute

    def initialize(type, length_attribute)
      @type = type
      @length_attribute = length_attribute
    end

    def to_native(value, struct, external_name, internal_name)
      pointer = case value
                when nil
                  ::FFI::MemoryPointer::NULL
                when Array
                  type.to_array_pointer(value)
                else
                  raise "`#{value}` (#{value.class}) should be an Array"
                end

      position = struct.internal.offset_of(internal_name)
      struct.internal.pointer.put_pointer(position, pointer)
      struct.remember_pointer(pointer, external_name)
    end

    def from_native(struct, _external_name, internal_name)
      return [] if struct.internal[internal_name].null?

      val_array = ::FFI::Pointer.new(type, struct.internal[internal_name])

      0.upto(struct.send(length_attribute) - 1).map do |index|
        type.from_pointer(val_array[index])
      end
    end
  end
end
