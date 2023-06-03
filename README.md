# WhereRow

A minimalistic Rails gem to allow easy use of SQL row value syntax.

Sometimes, the classic offset method to paginate results can be very inneficient, and not the best approach for some problems such as infinite scrolling. The seek method is a good alternative for these cases.

Consider the following example, as it appears on [Use The Index Luke](https://use-the-index-luke.com/sql/partial-results/fetch-next-page)

```SQL
CREATE INDEX sl_dtid ON sales (sale_date, sale_id)

SELECT *
  FROM sales
 WHERE (sale_date, sale_id) < (?, ?)
 ORDER BY sale_date DESC, sale_id DESC
 FETCH FIRST 10 ROWS ONLY
```

The Row Value syntax is straigth not supported in Rails in any way. Furthermore, some databases still don't support this syntax as well, or
maybe there is partial support (for example, the index is not properly utilized).

Thankfully, the same results can be achieved with plain-old logical expressions and comparisons. The equivalent query would look like this:

```SQL
 SELECT *
  FROM sales
 WHERE sale_date <= ?
 AND NOT (sale_date = ? AND sale_id >= ?)
 ORDER BY sale_date DESC, sale_id DESC
 FETCH FIRST 10 ROWS ONLY
```

This is something that can be directly expressed in Rails/ One possible way is the following:

```ruby
    Sales.
        where(sale_date: (..date_offset)).
        where.not(sale_date: date_offset, sale_id: (sale_id_offset..)).
        order(sale_date: :desc, sale_id: :desc).
        limit(10)
```

However, the intent of this query is not clear at all when reading through this piece of code. Furthermore, if for any reason we need more than two columns, this will blow up pretty quickly. This gem allows us to generate this query/relation with a more explicit syntax.

```ruby
    Sales.
        where_row(:sale_date, :sale_id).lt(date_offset, sale_id_offset).
        order(sale_date: :desc, sale_id: :desc).
        limit(10)
```

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'where_row'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install where_row

## Usage

A single `where_row` method is made available for all relations.

```ruby
date = Date.new(2021, 4, 5)

Sales.where_row(:sale_date, :sale_id).eq(date, 42)
Sales.where_row(:sale_date, :sale_id).in([date, 42], [date + 1.day, 43])
Sales.where_row(:sale_date, :sale_id).lt(date, 42)
Sales.where_row(:sale_date, :sale_id).gt(date, 42)
Sales.where_row(:sale_date, :sale_id).gte(date, 42)
Sales.where_row(:sale_date, :sale_id).lte(date, 42)
```

There is also a `not` method for negated queries.

```ruby
Sales.where_row(:sale_date, :sale_id).not.eq(date, 42)
```

The result is also a relation, so it can be chained with regular Rails query methods.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/odydoum/where_row.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
