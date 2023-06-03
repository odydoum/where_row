require 'where_row/query_builder_fascade'

module WhereRow
  module ActiveRecord
    module Relation
      def where_row(key, *keys)
        ::WhereRow::QueryBuilderFascade.new(self, [key] + keys)
      end
    end
  end
end
