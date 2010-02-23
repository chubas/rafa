require File.dirname(__FILE__) + '/raphael_element'

module Rafa
  module Elements

    # Represents the _ellipse_ object in raphael
    # See http://raphaeljs.com/reference.html#ellipse
    class Ellipse < RaphaelElement
      def initialize(canvas, center_x, center_y, radius_x, radius_y, options = {})
        super(canvas, options)
        args = [center_x, center_y, radius_x, radius_y]
        @canvas << "var #{@name} = #{@canvas.name}.ellipse(#{args.to_js_args});"
        apply_attributes(options)
      end
    end

  end
end