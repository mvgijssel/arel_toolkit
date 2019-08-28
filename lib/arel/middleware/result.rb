module Arel
  module Middleware
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
        @columns ||= from_caster.columns(original_data)
      end

      def rows
        @rows ||= from_caster.rows(original_data)
      end

      def remove_column(column_name)
        column_index = column_names.index(column_name)

        if column_index.nil?
          raise "Unknown column `#{column_name}`. Existing columns: `#{column_names}`"
        end

        mark_modified

        columns.delete_at(column_index)
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
              length = column_names.length

              while index < length
                hash[column_names[index]] = row[index]
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

      def mark_modified
        @hash_rows = nil
        @column_names = nil
        @modified = true
      end

      def column_names
        @column_names ||= columns.map(&:name)
      end
    end

    class Result
      class Array
        def self.cast_to(result)
          result.rows
        end
      end
    end

    class Result
      class String
        class << self
          def column_objects(_string)
            []
          end

          def rows(_string)
            []
          end

          def cast_to(result)
            result.original_data
          end
        end
      end
    end
  end
end
