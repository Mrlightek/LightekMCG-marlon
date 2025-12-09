# lib/marlon/ui_schema/builder.rb
module Marlon
  module UISchema
    class Builder
      def initialize
        @tree = []
      end

      def text(value)
        @tree << { type: "text", content: value }
      end

      def button(title, action:, **opts)
        @tree << { type: "button", title: title, action: action, props: opts }
      end

      def list(collection:, &blk)
        node = { type: "list", collection: collection, template: capture(&blk) }
        @tree << node
      end

      def form(fields = {}, &blk)
        @tree << { type: "form", fields: fields, template: capture(&blk) }
      end

      def raw(obj)
        @tree << obj
      end

      def to_h
        { ui: @tree }
      end

      private

      def capture(&blk)
        builder = self.class.new
        builder.instance_eval(&blk)
        builder.to_h
      end
    end

    def self.build(&blk)
      b = Builder.new
      b.instance_eval(&blk)
      b.to_h
    end
  end
end
