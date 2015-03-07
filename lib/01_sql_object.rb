require_relative 'db_connection'
require 'active_support/inflector'
# NB: the attr_accessor we wrote in phase 0 is NOT used in the rest
# of this project. It was only a warm up.

class SQLObject
  def self.columns
    DBConnection.execute2("SELECT * FROM #{table_name}")[0]
      .map { |val| val.to_sym }
  end

  def self.finalize!
    columns.each do |col|
      define_method(col) do
        attributes[col]
      end

      define_method("#{col}=") do |val|
        attributes[col] = val
      end
    end
  end

  def self.table_name=(table_name)
    @table_name = table_name
  end

  def self.table_name
    @table_name ||= self.to_s.tableize
  end

  def self.all
    parse_all(DBConnection.execute(<<-SQL))
      SELECT
        #{table_name}.*
      FROM
        #{table_name}
    SQL
  end

  def self.parse_all(results)
    results.map { |hash| self.new(hash) }
  end

  def self.find(id)
    ret = DBConnection.execute(<<-SQL, id)
      SELECT
        *
      FROM
        #{table_name} AS t
      WHERE
        t.id = ?
    SQL
    return nil if ret.empty?
    self.new(ret[0])
  end

  def initialize(params = {})
    cols = self.class.columns
    params.each do |attr_name, value|
      attr_name = attr_name.to_sym
      raise "unknown attribute '#{attr_name}'" unless cols.include?(attr_name)
      send("#{attr_name}=", value)
    end
  end

  def attributes
    @attributes ||= {}
  end

  def attribute_values
    self.class.columns.map { |col_name| send(col_name) }
  end

  def insert
    col_names = self.class.columns.join(", ")
    question_marks = (["?"] * (self.class.columns.length)).join(", ")
    DBConnection.execute(<<-SQL, *attribute_values)
      INSERT INTO
        #{self.class.table_name} (#{col_names})
      VALUES
        (#{question_marks})
    SQL
    send("id=", DBConnection.last_insert_row_id)
  end

  def update
    set_field = self.class.columns.map { |name| "#{name} = ?"}.join(", ")

    DBConnection.execute(<<-SQL, *(attribute_values << id))
      UPDATE
        #{self.class.table_name}
      SET
        #{set_field}
      WHERE
        id = ?
    SQL
  end

  def save
    id.nil? ? insert : update
  end
end
