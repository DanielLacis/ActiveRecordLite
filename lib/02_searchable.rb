require_relative 'db_connection'
require_relative '01_sql_object'

module Searchable
  def where(params)
    where_field = params.keys.map { |key| "#{key} = ?"}.join(" AND ")
    values = params.values
    parse_all(DBConnection.execute(<<-SQL, *values))
      SELECT
        *
      FROM
        #{table_name}
      WHERE
        #{where_field}
    SQL
  end
end

class SQLObject
  extend Searchable
end
