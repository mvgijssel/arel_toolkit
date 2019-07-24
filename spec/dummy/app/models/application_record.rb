class ApplicationRecord < ActiveRecord::Base
  self.table_name_prefix = 'dummy_'
  self.abstract_class = true
end
