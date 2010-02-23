require File.dirname(__FILE__) + '/javascript_literal'

module Rafa
  module Elements

    # Proxy for the method getBBox for raphael elements.
    # Note that it is only a proxy in the sense that the actual method is
    # to be called by javascript code, so there is no way to know the results of it.
    # However, it provides a way to wrap the resulting variables 
    class BBox
      attr_accessor :element

      def initialize(element, name = nil)
        @element = element
        @name = name || element.name + "_bbox"
        inject_js
        @name
      end

      # If the bounding box changed (updated position, width or height)
      # it forces a new bbox request
      def update!
        inject_js(true)
        self
      end

      # Wrapper for +x+ attribute of raphael _BBox_ object
      def x
        attr('x')
      end

      # Wrapper for +y+ attribute of raphael _BBox_ object
      def y
        attr('y')
      end

      # Wrapper for +width+ attribute of raphael _BBox_ object
      def width
        attr('width')
      end
      alias :w :width

      # Wrapper for +height+ attribute of raphael _BBox_ object
      def height
        attr('height')
      end
      alias :h :height

      private
      def attr(name) #:nodoc:
        varname = @name + '_' + name
        @element.canvas << "var #{varname} = #{@name}.#{name};"
        return JavascriptLiteral.new(varname)
      end

      def inject_js(reload = false)
        @element.canvas << "#{'var' if reload} #{@name} = #{@element.name}.getBBox();"
      end

    end
  end
end
