require_relative '02_searchable'
require 'active_support/inflector'

# Phase IIIa
class AssocOptions
  attr_accessor :foreign_key, :class_name, :primary_key

  def model_class
    class_name.constantize
  end

  def table_name
    model_class.table_name
  end
end

class BelongsToOptions < AssocOptions
  def initialize(name, options = {})
    defaults = {
      foreign_key: "#{name.to_s + "_id"}".to_sym,
      :primary_key => :id,
      class_name: name.to_s.camelcase
    }

    options = defaults.merge(options)
    @foreign_key = options[:foreign_key]
    @primary_key = options[:primary_key]
    @class_name = options[:class_name]
  end
end

class HasManyOptions < AssocOptions
  def initialize(name, self_class_name, options = {})
    defaults = { foreign_key: "#{self_class_name.to_s.underscore + "_id"}".to_sym,
                 :primary_key => :id,
                 class_name: name.to_s.camelcase.singularize
               }
    options = defaults.merge(options)
    @foreign_key = options[:foreign_key]
    @primary_key = options[:primary_key]
    @class_name = options[:class_name]
  end
end

module Associatable
  def belongs_to(name, options = {})
    options = BelongsToOptions.new(name, options)
    self.assoc_options[name] = options

    define_method(name) do
      foreign_key = send(options.foreign_key)
      primary_key = options.primary_key
      model_class = options.model_class
      model_class.where(primary_key => foreign_key).first
    end
  end

  def has_many(name, options = {})
    options = HasManyOptions.new(name, self, options)
    define_method(name) do
      foreign_key = options.foreign_key
      primary_key = send(options.primary_key)
      model_class = options.model_class
      model_class.where( { foreign_key => primary_key })
    end
  end

  def assoc_options
    @class_options ||= {}
  end
end

class SQLObject
  extend Associatable
end
