require File.dirname(__FILE__) + '/raphael_element'

module Rafa
  module Elements

    # Represents the _text_ object in raphael
    # See http://raphaeljs.com/reference.html#text
    class Text < RaphaelElement
      def initialize(canvas, x, y, text, options = {})
        super(canvas, options)
        args = [x, y, text]
        @canvas << "var #{@name} = #{@canvas.name}.text(#{args.to_js_args});"
        apply_attributes(options)
      end
    end

  end
end