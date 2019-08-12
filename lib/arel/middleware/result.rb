module Arel
  module Middleware
    class Column
      attr_reader :name
      attr_reader :metadata

      def initialize(name, metadata)
        @name = name
        @metadata = metadata
      end
    end

    # Class is very similar to ActiveRecord::Result
    # activerecord/lib/active_record/result.rb
    class Result
      attr_reader :original_data

      def self.create(from:, to:, data:)
        Result.new from, to, data
      end

      def initialize(from_caster, to_caster, original_data)
        @from_caster = from_caster
        @to_caster = to_caster
        @original_data = original_data
        @modified = false
      end

      def columns
        @columns ||= column_objects.map(&:name)
      end

      def column_objects
        @column_objects ||= from_caster.column_objects(original_data)
      end

      def rows
        @rows ||= from_caster.rows(original_data)
      end

      def remove_column(column_name)
        column_index = columns.index(column_name)
        raise "Unknown column `#{column_name}`. Existing columns: `#{columns}`" if column_index.nil?

        @hash_rows = nil
        @columns = nil
        @modified = true

        column_objects.delete_at(column_index)
        deleted_rows = []

        rows.map! do |row|
          deleted_rows << row.delete_at(column_index)
          row
        end

        deleted_rows
      end

      def hash_rows
        @hash_rows ||=
          begin
            rows.map do |row|
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

      def to_casted_result
        to_caster.cast_to(self)
      end

      def modified?
        @modified
      end

      private

      attr_reader :to_caster, :from_caster
    end

    class PGResult
      class << self
        def column_objects(pg_result)
          pg_result.fields.each_with_index.map do |field, index|
            Column.new(
              field,
              fmod: pg_result.fmod(index),
              ftype: pg_result.ftype(index),
            )
          end
        end

        def rows(data)
          data.values
        end

        def cast_to(result)
          if result.modified?
            instance = new(result)
            result.original_data.clear
            instance
          else
            result.original_data
          end
        end
      end

      attr_reader :fields, :values, :original

      # Object based on https://github.com/ged/ruby-pg/blob/v1.1.4/lib/pg/result.rb
      # The object is instantiated in C, so we cannot simply make a new PG::Result
      # Therefore we're ducktyping, with similar methods as the original object.
      def initialize(result)
        @fields = result.columns
        @fmods = []
        @ftypes = []

        result.column_objects.each do |column_object|
          @fmods << column_object.metadata.fetch(:fmod)
          @ftypes << column_object.metadata.fetch(:ftype)
        end

        @values = result.rows
        @original = result
      end

      def ftype(index)
        @ftypes[index]
      end

      def fmod(index)
        @fmods[index]
      end

      def clear; end
    end

    class ArrayResult
      def self.cast_to(result)
        result.rows
      end
    end
  end
end
