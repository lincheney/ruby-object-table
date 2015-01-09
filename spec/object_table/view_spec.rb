require 'object_table'
require 'object_table/view'

require 'support/object_table_example'
require 'support/view_example'

describe ObjectTable::View do
  it_behaves_like 'an object table', ObjectTable::View
  it_behaves_like 'a table view', ObjectTable::View

end
