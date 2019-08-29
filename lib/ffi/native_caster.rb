module FFI
  class NativeCaster
    class << self
      def to_native(value, struct, attribute_name)
        struct.internal[attribute_name] = value
      end

      def from_native(struct, attribute_name)
        struct.internal[attribute_name]
      end
    end
  end
end
