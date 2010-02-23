require File.dirname(__FILE__) + '/raphael_element'

module Rafa
  module Elements

    # Represents the _image_ object in raphael
    # See http://raphaeljs.com/reference.html#image
    class Image < RaphaelElement
      def initialize(canvas, uri, x, y, width, height, options = {})
        super(canvas, options)
        args = [uri, x, y, width, height]
        @canvas << "var #{@name} = #{@canvas.name}.image(#{args.to_js_args});"
        apply_attributes(options)
      end
    end

  end
end
