module WhereRow
  module ActiveRecord
    module Base
      def where_row(*args)
        all.where_row(*args)
      end
    end
  end
end
