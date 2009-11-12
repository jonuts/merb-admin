module MerbAdmin
  module ConfigMixin
    def self.incuded(model)
      ModelSetup.register(model.name.to_sym)
      model.extend ClassMethods
    end

    module ClassMethods
      def admin_config(&blk)
        ModelSetup[name.to_sym].instance_eval(&blk)
      end
    end
  end
end

