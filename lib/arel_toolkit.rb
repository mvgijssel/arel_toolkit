# Make sure the extensions are loaded before ArelToolkit
require 'postgres_ext' if Gem.loaded_specs.key?('postgres_ext')
require 'active_record_upsert' if Gem.loaded_specs.key?('active_record_upsert')
require 'pg_search' if Gem.loaded_specs.key?('pg_search')

require 'arel_toolkit/version'
require 'arel_toolkit/railtie' if defined? Rails
require 'arel'
require 'arel/extensions'
require 'arel/sql_to_arel'
require 'arel/middleware'
require 'arel/transformer'

module ArelToolkit
end
