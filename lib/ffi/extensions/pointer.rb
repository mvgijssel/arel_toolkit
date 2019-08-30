module FFI
  class Pointer
    # copied from https://github.com/ffi/ffi/commit/c7afdbdd8fb79c50f9dd9dd0f8415bb29ce74668
    def read_array_of(type, size, length)
      Array.new(length) do |index|
        get(type, index * size)
      end
    end

    def write_array_of(type, size, ary)
      ary.each_with_index do |value, index|
        put(type, index * size, value)
      end
      self
    end
  end
end
