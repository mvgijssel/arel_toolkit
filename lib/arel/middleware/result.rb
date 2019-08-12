module Arel
  module Middleware
    # Class is very similar to ActiveRecord::Result
    # activerecord/lib/active_record/result.rb
    class Result
      def self.create(from:, to:, data:)
        Result.new from, to, data
      end

      def initialize(from_caster, to_caster, data)
        @from_caster = from_caster
        @to_caster = to_caster
        @data = data
      end

      def columns
        @columns ||= from_caster.columns(data)
      end

      def rows
        @rows ||= from_caster.rows(data)
      end

      def hash_rows
        @hash_rows ||=
          begin
            # We freeze the strings to prevent them getting duped when
            # used as keys in ActiveRecord::Base's @attributes hash
            columns = @columns.map { |c| c.dup.freeze }
            @rows.map do |row|
              # In the past we used Hash[columns.zip(row)]
              #  though elegant, the verbose way is much more efficient
              #  both time and memory wise cause it avoids a big array allocation
              #  this method is called a lot and needs to be micro optimised
              hash = {}

              index = 0
              length = columns.length

              while index < length
                hash[columns[index]] = row[index]
                index += 1
              end

              hash
            end
          end
      end

      def to_original_result
        to_caster.cast_to(self)
      end

      private

      attr_reader :to_caster, :from_caster, :data
    end

    class PGResult
      def self.columns(data)
        data.fields
      end

      def self.rows(data)
        data.values
      end

      # .fields
      # .values
      # .clear
      def self.cast_to(result)
        # TODO: make a PG::Result object
        result.send(:data)
      end
    end

    class ArrayResult
      def self.columns(data)
        raise "ArrayResult data does not have columns: #{data}"
      end

      def self.rows(data)
        data
      end

      def self.cast_to(result)
        result.rows
      end
    end
  end
end
