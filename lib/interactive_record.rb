require_relative "../config/environment.rb"
require 'active_support/inflector'
require 'pry'

class InteractiveRecord

  def self.table_name
    self.to_s.downcase.pluralize
  end

  def self.column_names
    DB[:conn].results_as_hash = true
    sql = "PRAGMA table_info ('#{table_name}')"
    table_info = DB[:conn].execute(sql)
    table_info.map {|c| c["name"]}.compact
  end

  def initialize(options = {})
    options.each {|p, v| self.send("#{p}=", v)}
  end

  def table_name_for_insert
    self.class.table_name
  end

  def col_names_for_insert
    self.class.column_names.delete_if{|c| c=="id"}.join(", ")
  end

  def values_for_insert
    value =[]
    self.class.column_names.each do |c|
      value << "'#{send(c)}'" unless send(c).nil?
    end
    value.join(", ")
  end

  def save
    sql = "INSERT INTO #{table_name_for_insert} (#{col_names_for_insert}) VALUES (#{values_for_insert})"
    DB[:conn].execute(sql)
    @id = DB[:conn].execute("SELECT last_insert_rowid() FROM #{table_name_for_insert}")[0][0]
  end

  def self.find_by_name (name)
    #sql = "SELECT * FROM #{self.table_name} WHERE name = '#{name}'"
    #DB[:conn].execute(sql)
    self.find_by(name: name)
  end

  def self.find_by (query)
    key = query.keys[0]
    value = query.values[0]
    sql = ""
    if value.is_a?(Integer)
      sql = "SELECT * FROM #{self.table_name} WHERE #{key} = #{value}"
    else
      sql = "SELECT * FROM #{self.table_name} WHERE #{key} = '#{value}'"
    end
    DB[:conn].execute(sql)
  end
end
