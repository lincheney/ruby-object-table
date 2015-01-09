require 'object_table'
require 'object_table/static_view'

require 'support/object_table_example'
require 'support/view_example'

describe ObjectTable::StaticView do
  it_behaves_like 'an object table', ObjectTable::StaticView
  it_behaves_like 'a table view', ObjectTable::StaticView
end
