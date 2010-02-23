require File.dirname(__FILE__) + '/raphael_element'

module Rafa
  module Elements

    # Represents the _circle_ object in raphael
    # See http://raphaeljs.com/reference.html#circle
    class Circle < RaphaelElement
      def initialize(canvas, center_x, center_y, radius, options = {})
        super(canvas, options)
        args = [center_x, center_y, radius]
        @canvas << "var #{@name} = #{@canvas.name}.circle(#{args.to_js_args});"
        apply_attributes(options)
      end
    end

  end
end