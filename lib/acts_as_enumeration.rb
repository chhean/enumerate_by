require 'acts_as_enumeration/extensions/associations'
require 'acts_as_enumeration/extensions/base_conditions'

module PluginAWeek #:nodoc:
  module Acts #:nodoc:
    # An enumeration defines a finite set of identifiers which (often) have no
    # numerical order.  This plugin provides a general technique for using
    # ActiveRecord classes to defined enumerations.
    # 
    # == Defining enumerations
    # 
    # To define an ActiveRecord class as an enumeration:
    # 
    #   class Color < ActiveRecord::Base
    #     acts_as_enumeration
    #   end
    # 
    # This will create the class/instance methods for accessing the enumeration
    # identifiers.
    # 
    # == Accessing enumeration identifiers
    # 
    # The actual records for an enumeration identifier can be accessed by id or
    # name:
    # 
    #   >> Color[:red]
    #   => #<Color:0x480c808 @attributes={"name"=>"red", "id"=>"1"}>
    #   >> Color[1]
    #   => #<Color:0x480c808 @attributes={"name"=>"red", "id"=>"1"}>
    # 
    # == Caching
    # 
    # On first access, all records in the enumeration are cached so that any
    # further accesses do not hit the database.  When new models are created or
    # existing models are saved, the cache is reset.
    # 
    # To manually reset the cached, you can call #reset_cache.
    module Enumeration
      def self.included(base) #:nodoc:
        base.extend(MacroMethods)
      end
      
      module MacroMethods
        # Indicates that this class is a representative of an enumeration.
        def acts_as_enumeration
          validates_uniqueness_of :name
          
          before_save Proc.new {|model| model.class.reset_cache}
          before_destroy Proc.new {|model| model.class.reset_cache}
          
          extend PluginAWeek::Acts::Enumeration::ClassMethods
          include PluginAWeek::Acts::Enumeration::InstanceMethods
        end
        
        # Is this class an enumeration?
        def enumeration?
          extended_by.include?(PluginAWeek::Acts::Enumeration::ClassMethods)
        end
      end
      
      module ClassMethods
        # Finds all of the values in this enumeration.  The values will be cached
        # until the cache is reset either manually or automatically when the
        # model chanages
        def all
          @all ||= find(:all).map(&:freeze).freeze
        end
        
        # Looks up the corresponding record.  You can lookup the following types:
        # * symbol - The symbol name of the enum value
        # * string - The name of the enum value
        # * fixnum - The id of the record
        # 
        # Any other type will cause a TypeError exception to be raised.  If a
        # record cannot be found, then a RecordNotFound exception will be raised.
        # 
        # If you do not want to worry about exceptions, then use find_by_id or
        # find_by_name.
        def [](id)
          find_enum(id) || raise(ActiveRecord::RecordNotFound, "Couldn't find #{name} for #{id}")
        end
        
        # Determines whether this enumeration includes the given id
        def includes?(id)
          !find_enum(id).nil?
        end
        
        # Resets the colletion of values in the enumeration
        def reset_cache
          @all = @all_by_name = @all_by_id = nil
        end
        
        # Finds the enumerated value with the given id
        def find_by_id(id)
          @all_by_id ||= all.inject({}) {|memo, item| memo[item.id] = item; memo;}.freeze
          @all_by_id[id]
        end
        
        # Finds the enumerated value with the given name
        def find_by_name(name)
          @all_by_name ||= all.inject({}) {|memo, item| memo[item.name] = item; memo;}.freeze
          @all_by_name[name.is_a?(Symbol) ? name.id2name : name]
        end
        
        private
          def find_enum(id)
            case id
              when Symbol
                value = find_by_name(id.id2name)
              when String
                value = find_by_name(id)
              when Fixnum
                value = find_by_id(id)
              when nil
                value = nil
              else
                raise TypeError, "#{self.name}[]: id should be a String, Symbol or Fixnum but got a: #{id.class.name}"
            end
            
            value
          end
      end
      
      module InstanceMethods
        # Whether or not this enumeration is equal to the given value
        def ===(arg)
          case arg
            when Symbol, String, Fixnum, nil
              return self == self.class[arg]
            when Array
              return in?(*arg)
            end
          
          super
        end
        
        # Determines whether this enumeration is in the given list
        def in?(*list)
          list.any? {|item| self === item}
        end
        
        # Returns the symbol value of the name
        def to_sym
          self.name.to_sym
        end
      end
    end
  end
end

ActiveRecord::Base.class_eval do
  include PluginAWeek::Acts::Enumeration
end