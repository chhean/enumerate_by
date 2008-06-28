module Factory
  # Build actions for the model
  def self.build(model, &block)
    name = model.to_s.underscore
    
    define_method("#{name}_attributes", block)
    define_method("valid_#{name}_attributes") {|*args| valid_attributes_for(model, *args)}
    define_method("new_#{name}")              {|*args| new_record(model, *args)}
    define_method("create_#{name}")           {|*args| create_record(model, *args)}
  end
  
  # Get valid attributes for the model
  def valid_attributes_for(model, attributes = {})
    name = model.to_s.underscore
    send("#{name}_attributes", attributes)
    attributes
  end
  
  # Build an unsaved record
  def new_record(model, *args)
    model.new(valid_attributes_for(model, *args))
  end
  
  # Build and save/reload a record
  def create_record(model, *args)
    record = new_record(model, *args)
    record.save!
    record.reload
    record
  end
  
  build Book do |attributes|
    attributes.reverse_merge!(
      :id => 1,
      :title => 'Blink'
    )
  end
  
  build Car do |attributes|
    attributes.reverse_merge!(
      :name => 'Ford Mustang',
      :color_id => 1
    )
  end
  
  build Color do |attributes|
    attributes.reverse_merge!(
      :id => 1,
      :name => 'red'
    )
  end
  
  build Country do |attributes|
    attributes.reverse_merge!(
      :id => 1,
      :name => 'United States'
    )
  end
  
  build Language do |attributes|
    attributes[:country] = create_country unless attributes.include?(:country)
    attributes.reverse_merge!(
      :id => 1,
      :name => 'English'
    )
  end
  
  build Passenger do |attributes|
    attributes[:car] = create_car unless attributes.include?(:car)
  end
  
  build Region do |attributes|
    attributes[:country] = create_country unless attributes.include?(:country)
    attributes.reverse_merge!(
      :id => 1,
      :name => 'New Jersey'
    )
  end
end
