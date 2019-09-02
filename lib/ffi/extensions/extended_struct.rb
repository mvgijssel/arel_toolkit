module FFI
  class ExtendedStruct < FFI::Struct
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

    def self.from_pointer(pointer)
      new(pointer, {})
    end

    def self.from_data(**kwargs)
      new(nil, kwargs)
    end

    # TODO: remove this
    def self.to_array_pointer(items)
      # Create a memory pointer to hold all of the array items
      array_pointer = ::FFI::MemoryPointer.new(size, items.length)

      # Read the bytes of each struct and store these bytes in
      # the right place in the memory pointer
      items.each_with_index do |item, index|
        item_bytes = item.pointer.get_bytes(0, size)
        array_pointer[index].put_bytes(0, item_bytes)
      end

      array_pointer
    end

    def self.attributes
      @attributes
    end

    def self.ensure_layout
      return if @layout

      ref_layout = attributes.map do |_name, value|
        [value.fetch(:internal_name), value.fetch(:type)]
      end.flatten

      layout(*ref_layout)
    end

    def initialize(pointer = nil, **kwargs)
      @remembered_pointers = {}

      self.class.ensure_layout

      super(pointer)

      self.class.attributes.each do |name, _value|
        public_send "#{name}=", kwargs.fetch(name, public_send(name))
      end
    end

    def remember_pointer(pointer, attribute_name)
      @remembered_pointers[attribute_name] = pointer
    end
  end
end
