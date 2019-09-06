require 'mkmf'

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

# puts Gem.loaded_specs

# pg_ext = Gem.loaded_specs.fetch('pg').stub
# pg_ext_inlude_dir = File.join(pg_ext.full_gem_path, 'ext')
# pg_ext_lib_dir = pg_ext.extension_dir

# dir_config(
#   'pg_ext',
#   pg_ext_inlude_dir,
#   pg_ext_lib_dir,
# )

if (
    have_library('pq') ||
    have_library('libpq') ||
    have_library('ms/libpq')
  ) &&
   have_header('libpq-fe.h')
   # && have_header('pg.h')

  # have_func 'PQsetSingleRowMode'
  # have_func 'timegm'

  # TODO: check pg_result_init.c for required enums / functions

  create_makefile('pg_result_init/pg_result_init')
else
  puts 'Could not find PostgreSQL build environment (libraries & headers): Makefile not created'
end
