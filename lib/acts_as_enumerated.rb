require 'acts_as_enumerated/acts/enumerated'
require 'acts_as_enumerated/associations/has_enumerated'

ActiveRecord::Base.class_eval do
  include PluginAWeek::Acts::Enumerated
  include PluginAWeek::Aggregations::HasEnumerated
end