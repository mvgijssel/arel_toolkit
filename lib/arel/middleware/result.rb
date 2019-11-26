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
              tableid: pg_result.ftable(index),
              columnid: pg_result.ftablecol(index),
              format: pg_result.fformat(index),
              typid: pg_result.ftype(index),
              typlen: pg_result.fsize(index),
              atttypmod: pg_result.fmod(index)
            )
          end
        end

        def rows(data)
          data.values
        end

        def cast_to(result)
          return result.original_data unless result.modified?

          pg_columns = result_to_columns(result)
          conn = ActiveRecord::Base.connection.raw_connection
          new_result = PgResultInit.create(conn, result.original_data, pg_columns, result.rows)
          result.original_data.clear
          new_result
        end

        private

        def result_to_columns(result)
          result.column_objects.map do |column|
            {
              name: column.name,
              tableid: column.metadata.fetch(:tableid, 0),
              columnid: column.metadata.fetch(:columnid, 0),
              format: column.metadata.fetch(:format, 0),
              typid: column.metadata.fetch(:typid),
              typlen: column.metadata.fetch(:typlen),
              atttypmod: column.metadata.fetch(:atttypmod, -1)
            }
          end
        end
      end
    end

    class EmptyPGResult < PGResult
      class << self
        def cast_to(_result)
          ActiveRecord::Base.connection.raw_connection.make_empty_pgresult(2)
        end
      end
    end

    class ArrayResult
      def self.cast_to(result)
        result.rows
      end
    end

    class StringResult
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
