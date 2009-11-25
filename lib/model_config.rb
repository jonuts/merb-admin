module MerbAdmin
  class ModelConfig
    @models ||= []

    class <<self
      attr_reader :models

      def set(name, &config_blk)
        model = new(name, &config_blk)
        model.instance_eval(&config_blk)
        @models << model
      end
    end

    def initialize(name)
      @name = name
    end

    attr_reader :listed_fields

    def list_fields(*fields)
      @listed_fields = fields
    end
  end
end
