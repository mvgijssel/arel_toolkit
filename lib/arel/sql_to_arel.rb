require 'arel/sql_to_arel/pg_query_visitor'
require 'arel/sql_to_arel/unbound_column_reference'

module Arel
  def self.sql_to_arel(sql, binds: [])
    SqlToArel::PgQueryVisitor.new.accept(sql, binds)
  end
end
