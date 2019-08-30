module FFI
  class ExtendedStruct
    def self.attribute(name, type, caster: NativeCaster, as: nil)
      external_name = as || name
      internal_name = name

      define_method(external_name) do
        instance_variable_get("@#{external_name}") || instance_variable_set(
          "@#{external_name}",
          caster.from_native(self, external_name, internal_name),
        )
      end

      define_method("#{external_name}=") do |value|
        instance_variable_set("@#{external_name}", value)
        caster.to_native(value, self, external_name, internal_name)
      end

      type_def = enclosing_module.respond_to?(:find_type) ? enclosing_module : FFI

      @attributes ||= {}
      @attributes[external_name.to_sym] = {
        internal_name: internal_name,
        external_name: external_name,
        type: type_def.find_type(type),
        type_name: type,
        caster: caster,
      }
    end

    def self.enclosing_module
      @enclosing_module ||= begin
                              ref = self

                              wrapper = Class.new(FFI::Struct) do
                                define_singleton_method(:name) do
                                  ref.name
                                end
                              end

                              wrapper.send(:enclosing_module)
                            end
    end

    def self.from_pointer(pointer)
      new(pointer, {})
    end

    def self.to_array_pointer(items)
      # Create a memory pointer to hold all of the array items
      array_pointer = ::FFI::MemoryPointer.new(size, items.length)

      # Read the bytes of each struct and store these bytes in
      # the right place in the memory pointer
      items.each_with_index do |item, index|
        item_bytes = item.internal.pointer.get_bytes(0, size)
        array_pointer[index].put_bytes(0, item_bytes)
      end

      array_pointer
    end

    def self.from_data(**kwargs)
      new(nil, kwargs)
    end

    def self.attributes
      @attributes
    end

    def self.internal_class
      ref = self

      @internal_class ||= Class.new(FFI::Struct) do
        ref_layout = ref.attributes.map do |_name, value|
          [value.fetch(:internal_name), value.fetch(:type)]
        end.flatten

        layout(*ref_layout)
      end
    end

    def self.size
      internal_class.size
    end

    attr_reader :internal

    def initialize(pointer = nil, **kwargs)
      @remembered_pointers = {}
      @internal = self.class.internal_class.new(pointer)

      self.class.attributes.each do |name, _value|
        public_send "#{name}=", kwargs.fetch(name, public_send(name))
      end
    end

    def remember_pointer(pointer, attribute_name)
      @remembered_pointers[attribute_name] = pointer
    end

    def size
      self.class.size
    end
  end
end
