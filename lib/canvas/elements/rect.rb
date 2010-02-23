require File.dirname(__FILE__) + '/raphael_element'

module Rafa
  module Elements

    # Represents the _rect_ object in raphael
    # See http://raphaeljs.com/reference.html#rect
    class Rect < RaphaelElement
      def initialize(canvas, topleft_x, topleft_y, width, height, radius_or_options = nil, options = {})
        if radius_or_options.kind_of? Hash
          radius  = nil
          options = radius_or_options
        else
          radius = options.delete('rounded') || options.delete(:rounded) || 0
        end
        super(canvas, options)
        args = [topleft_x, topleft_y, width, height, radius]
        @canvas << "var #{@name} = #{@canvas.name}.rect(#{args.to_js_args});"
        apply_attributes(options)
      end
    end

  end
end
