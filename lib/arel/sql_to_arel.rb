require 'arel/sql_to_arel/pg_query_visitor'
require 'arel/sql_to_arel/unbound_column_reference'

module Arel
  def self.sql_to_arel(sql, models: [])
    SqlToArel::PgQueryVisitor.new.accept(sql, models)
  end
end
