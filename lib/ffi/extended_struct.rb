module FFI
  class ExtendedStruct
    def self.attribute(name, type, caster = NativeCaster)
      define_method(name) do
        caster.from_native(self, name)
      end

      define_method("#{name}=") do |value|
        instance_variable_set("@#{name}", value)
        caster.to_native(value, self, name)
      end

      type_def = enclosing_module.respond_to?(:find_type) ? enclosing_module : FFI

      @attributes ||= {}
      @attributes[name.to_sym] = {
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

    def self.from_data(**kwargs)
      new(nil, kwargs)
    end

    def self.attributes
      @attributes
    end

    def self.internal_class
      ref = self

      @internal_class ||= Class.new(FFI::Struct) do
        ref_layout = ref.attributes.map do |name, value|
          [name, value.fetch(:type)]
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
