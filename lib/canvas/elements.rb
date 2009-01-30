require 'util/util'
require 'canvas/attributes'
require 'canvas/boundingbox'

module Rafa
  module Elements

    # This class is the superclass for all canvas elements, such as
    # Circle, Rect, Ellipse, Text and Path
    class BasicShape
      
      include Rafa::Elements::Attributes
      include Rafa::Util
      
      attr_accessor :canvas, :name, :bbox

      # At initialization, it generates a unique variable name to identify this element
      # in the javascript. It can be passed in _options_ parameter with the key :id
      def initialize(canvas, options = {})
        @canvas = canvas
        given_name = options.delete('id') || options.delete(:id)
        suffix = Time.now.to_i.to_s  # TODO: A better way to generate unique shorter ids
        classname = self.class.to_s.split("::").last.downcase
        @name = given_name || "rafa_#{classname}_#{suffix}"
      end

      # It applies the given attributes to the object.
      def apply_attributes(attributes)
        attributes.each { |k, v| self[k] = v }
        self
      end

      # Wrapper for the _rotate_ method of raphael.
      # The +absolute+ parameter indicates if the angle is absolute or relative to the
      # current one. The +mode+ parameters can be +:degrees+, which converts the
      # specified +angle+ into degrees properly
      def rotate(angle, absolute = true, mode = :degrees)
        if mode == :radians
          angle = radians_to_degrees(angle)
        end
        @canvas << "#{@name}.rotate(#{angle}, #{!!absolute});"
        self
      end

      # Wrapper for the +translate+ method of raphael.
      # Accepts a delta x and a delta y
      def translate(dx, dy)
        @canvas << "#{@name}.translate(#{dx}, #{dy})"
        self
      end

      # Wrapper for the +scale+ method of raphael.
      def scale(scaleX, scaleY)
        @canvas << "#{@name}.scale(#{scaleX}, #{scaleY})"
        self
      end

      # Scales just the x component. See +:scale+
      def scale_x(x)
        scale(x, 1)
      end

      # Scales just the y component. See +:scale+
      def scale_y(y)
        scale(1, y)
      end

      # Gets a wrapper for the bounding box of the element
      # Optional parameters in +args+:
      # * +:name+:: Gives a defined name to the javascript variable
      # * +:reload+:: Injects javascript in order to get again the bounding box.
      #               This is useful if you know the bounding box may have changed
      #               due to a resize or a translation
      def bbox(args = {})
        name = args.delete(:name) || nil
        if args[:reload]
          @bbox = BBox.new(self, name)
        else
          @bbox ||= BBox.new(self, name)
        end
      end

      # Wrapper for the +attr+ method of raphael
      # It sets the given value for the attribute to the element.
      # If the element is not in +Attributes::POSSIBLE_ATTRIBUTES+ it throws a warning
      # and returns nil.
      # If the value is a +JavascriptLiteral+ object, it gets printed to the javascript
      # verbatim. Other way, it is printed as a javascript string or numeric value.
      # The printed value is the result of calling the +to_json+ method of such object.
      def []=(attribute, value)
        attribute = attribute.to_s
        attribute = attribute.to_s.gsub(/[^a-zA-Z0-9_\-]/, '')
        unless POSSIBLE_ATTRIBUTES.include? attribute
          # FIXME: Log, don't print
          puts "Warning! Attribute #{attribute} not recognized"
          return nil
        end
        attr_str = {attribute => value}.to_json
        @canvas << "#{@name}.attr(#{attr_str})"
        return self
      end
      
      # Alias for +:[]+ method
      def attr(name, value)
        self[name] = value
      end

      # Tries to call the +:attr+ method. If it returns +nil+, continues
      # with a call to _super_ as normally expected.
      def method_missing(name, *args, &block)
        # FIXME: In case of returning nil
        if attr(name, args[0])
          self
        else
          super(name, *args, &block)
        end
      end

      # Wrapper for the raphael +node+ method. Returns the name of the variable
      # that holds the returning element
      def node
        nodename = "#{@name}_node"
        @canvas << "var #{nodename} = #{@name}.node;"
        nodename
      end

      # Wrapper for +toFront+ method of raphael
      def to_front
        @canvas << "#{@name}.toFront();"
        self
      end

      # Wrapper for the +toBack+ method of raphael
      def to_back
        @canvas << "#{@name}.toBack();"
        self
      end

    end

    # Represents the _circle_ object in raphael
    class Circle < BasicShape
      def initialize(canvas, center_x, center_y, radius, options = {})
        super(canvas, options)
        @canvas << "var #{@name} = #{@canvas.name}.circle(#{center_x}, #{center_y}, #{radius});"
        apply_attributes(options)
      end
    end

    # Represents the _rect_ object in raphael
    class Rect < BasicShape
      def initialize(canvas, topleft_x, topleft_y, width, height, options = {})
        rounded = options.delete('rounded') || options.delete(:rounded) || 0
        super(canvas, options)
        @canvas << 
          "var #{@name} = #{@canvas.name}.rect(" + 
            "#{topleft_x}, #{topleft_y}, #{width}, #{height}, #{rounded});"
      apply_attributes(options)
      end
    end

    # Represents the _ellipse_ object in raphael
    class Ellipse < BasicShape
      def initialize(canvas, center_x, center_y, radius_x, radius_y, options = {})
        super(canvas, options)
        @canvas << 
          "var #{@name} = #{@canvas.name}.ellipse(" +
            "#{center_x}, #{center_y}, #{radius_x}, #{radius_y});"
        apply_attributes(options)
      end
    end

    # Represents the _text_ object in raphael
    class Text < BasicShape
      def initialize(canvas, x, y, text, options = {})
        super(canvas, options)
        @canvas << 
          "var #{@name} = #{@canvas.name}.text(#{x}, #{y}, #{text.inspect});"
        apply_attributes(options)
      end
    end

  end
end
