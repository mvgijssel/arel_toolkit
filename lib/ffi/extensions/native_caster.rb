module FFI
  class NativeCaster
    class << self
      def to_native(value, struct, _external_name, internal_name)
        struct[internal_name] = value
      end

      def from_native(struct, _external_name, internal_name)
        struct[internal_name]
      end
    end
  end
end
