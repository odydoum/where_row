# frozen_string_literal: true
require "where_row/version"
require "where_row/active_record/relation"
require "where_row/active_record/base"

require "active_record"

module WhereRow; end

ActiveRecord::Relation.prepend ::WhereRow::ActiveRecord::Relation
ActiveRecord::Base.extend ::WhereRow::ActiveRecord::Base
