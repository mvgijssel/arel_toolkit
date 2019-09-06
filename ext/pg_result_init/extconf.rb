require 'mkmf'
require 'pg'

CONFIG['debugflags'] = '-ggdb3'
CONFIG['optflags'] = '-O0'

# https://github.com/jeremyevans/sequel_pg/blob/master/ext/sequel_pg/extconf.rb

pg_include_dir = ENV['POSTGRES_INCLUDE'] ||
                 (begin
                    IO.popen('pg_config --includedir').readline.chomp
                  rescue StandardError
                    nil
                  end)
pg_lib_dir = ENV['POSTGRES_LIB'] ||
             (begin
                IO.popen('pg_config --libdir').readline.chomp
              rescue StandardError
                nil
              end)

dir_config(
  'pg',
  pg_include_dir,
  pg_lib_dir,
)

pg_ext = Gem.loaded_specs.fetch('pg')
pg_ext_inlude_dir = File.join(pg_ext.full_gem_path, 'ext')
pg_ext_lib_dir = pg_ext.extension_dir

dir_config(
  'pg_ext',
  pg_ext_inlude_dir,
  pg_ext_lib_dir,
)

if (
    have_library('pq') ||
    have_library('libpq') ||
    have_library('ms/libpq')
  ) &&
   have_header('libpq-fe.h') &&
   have_header('pg.h') &&
   have_func('PQcopyResult') &&
   have_func('PQsetResultAttrs') &&
   have_func('PQsetvalue') &&


  create_makefile('arel_toolkit/pg_result_init')
else
  abort 'Could not find PostgreSQL build environment (libraries & headers): Makefile not created'
end
