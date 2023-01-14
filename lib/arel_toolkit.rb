# Make sure the gems are loaded before ArelToolkit
require 'rails/railtie' if Gem.loaded_specs.key?('railties')
require 'arel'
require 'active_record'
require 'active_record/connection_adapters/postgresql_adapter'

require 'arel_toolkit/version'

require 'pg'
require 'arel_toolkit/pg_result_init'

require 'arel/extensions'
require 'arel/sql_to_arel'
require 'arel/middleware'
require 'arel/enhance'
require 'arel/transformer'

module ArelToolkit
end
