module MerbAdmin
  class ModelSetup
    @@all ||= []

    def self.add(model) 
      @@all << model unless @@all.include?(model)
    end

    def self.[](name)
      @@all.find{|m| m.name == name}
    end

    def self.new(name, &blk)
      model = self[name]
      if model
        model.instance_eval(&blk)
      else
        new(name, &blk)
      end
    end

    attr_reader :name,
      :label_property,
      :included_fields,
      :included_relationships

    private

    def initialize(name,&blk)
      @name = name
      @included_fields = []
      @included_relationships = []
      intance_eval(&blk) if block_given?
      self.class.add(self)
    end

    def label(name)
      @label_property = name
    end

    def fields(*properties)
      @included_fields = properties
    end

    def relationships(*names)
      @included_relationships = names
    end
  end
end
