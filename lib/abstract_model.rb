module MerbAdmin
  class AbstractModel

    # Returns all models for a given Merb app
    def self.all
      return @models if @models
      @models ||= []
      case Merb.orm
      when :datamapper
        DataMapper::Resource.descendants.each do |m|
          # Remove DataMapperSessionStore because it's included by default
          next if m == Merb::DataMapperSessionStore if Merb.const_defined?(:DataMapperSessionStore)
          model = lookup(m.to_s.to_sym)
          @models << new(model) if model
        end
        @models.sort{|a, b| a.to_s <=> b.to_s}
      else
        raise "MerbAdmin does not currently support the #{Merb.orm} ORM"
      end
    end

    # Given a symbol +model_name+, finds the corresponding model class
    def self.lookup(model_name)
      model = const_get(model_name)
      raise "could not find model #{model_name}" if model.nil?
      return model if model.include?(DataMapper::Resource)
      nil
    end

    attr_accessor :model

    def initialize(model)
      model = self.class.lookup(model.camel_case.to_sym) unless model.is_a?(Class)
      @model = model
      self.extend(GenericSupport)
      case Merb.orm
      when :datamapper
        self.extend(DatamapperSupport)
      else
        raise "MerbAdmin does not currently support the #{Merb.orm} ORM"
      end
    end

    module GenericSupport
      def singular_name
        model.to_s.snake_case.to_sym
      end

      def plural_name
        model.to_s.snake_case.pluralize.to_sym
      end

      def pretty_name
        model.to_s.snake_case.gsub('_', ' ')
      end
    end

    module DatamapperSupport
      def count(options = {})
        model.count(options)
      end

      def find_all(options = {})
        model.all(options)
      end

      def find(id)
        model.get(id).extend(InstanceMethods)
      end

      def new(params = {})
        model.new(params).extend(InstanceMethods)
      end

      def has_many_associations
        associations.select do |association|
          association[:type] == :has_many
        end
      end

      def has_one_associations
        associations.select do |association|
          association[:type] == :has_one
        end
      end

      def belongs_to_associations
        associations.select do |association|
          association[:type] == :belongs_to
        end
      end

      def associations
        model.relationships.to_a.map do |name, relationship|
          {
            :name => name,
            :pretty_name => name.to_s.gsub('_', ' '),
            :type => association_type_lookup(relationship),
            :parent_model => relationship.parent_model,
            :parent_key => relationship.parent_key.map{|p| p.name},
            :child_model => relationship.child_model,
            :child_key => relationship.child_key.map{|p| p.name},
            :remote_relationship => relationship.options[:remote_relationship_name],
            :near_relationship => relationship.options[:near_relationship_name],
          }
        end
      end

      def association_names
        associations.map do |association|
          association[:type] == :belongs_to ? association[:parent_name] : association[:child_name]
        end
      end

      def properties
        model.properties.map do |property|
          {
            :name => property.name,
            :pretty_name => property.field.gsub('_', ' '),
            :nullable? => property.nullable?,
            :serial? => property.serial?,
            :key? => property.key?,
            :field => property.field,
            :length => property.length,
            :type => type_lookup(property),
            :flag_map => property.type.respond_to?(:flag_map) ? property.type.flag_map : nil,
          }
        end
      end

      private

      def association_type_lookup(relationship)
        if self.model == relationship.parent_model
          relationship.options[:max] > 1 ? :has_many : :has_one
        elsif self.model == relationship.child_model
          :belongs_to
        else
          raise "Unknown association type"
        end
      end

      def type_lookup(property)
        type = {
          DataMapper::Types::Serial => :integer,
          DataMapper::Types::Boolean => :boolean,
          DataMapper::Types::Text => :text,
          DataMapper::Types::ParanoidDateTime => :date_time,
          Integer => :integer,
          Fixnum => :integer,
          Float => :float,
          BigDecimal => :big_decimal,
          TrueClass => :boolean,
          String => :string,
          DateTime => :date_time,
          Date => :date,
          Time => :time,
        }
        type[property.type] || type[property.primitive]
      end

      module InstanceMethods
        def clear_association(association)
          association.clear
        end
      end

    end

  end
end