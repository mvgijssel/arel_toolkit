module FFI
  module Library
    module LibraryExtension
      def find_type(t)
        if t.is_a?(Class) && t < ::FFI::ExtendedStruct
          t.by_value
        else
          super(t)
        end
      end
    end

    prepend LibraryExtension
  end
end
