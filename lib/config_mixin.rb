module MerbAdmin
  module ConfigMixin
    def self.incuded(model)
      ModelSetup.new(model.name.to_s.snake_case.to_sym)
      model.extend ClassMethods
    end

    module ClassMethods
      def admin_config(&blk)
        MerbAdmin::ModelSetup.new(&blk)
      end
    end
  end
end

