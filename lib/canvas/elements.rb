dirname = File.dirname(__FILE__)
require File.join(dirname, '../util/util')
require File.join(dirname, '../canvas/attributes')
require File.join(dirname, '../canvas/boundingbox')

#--
# TODO: Refactor a way to call "#{@name}.method(#{arguments}) generically"
#++

module Rafa
  module Elements

    # This class is the superclass for all canvas elements, such as
    # Circle, Rect, Ellipse, Text and Path
    class BasicShape
      
      include Rafa::Elements::Attributes
      include Rafa::Util
      
      attr_accessor :canvas, :name, :bbox

      # Trick for chained methods to return themselves after a call.
      # Useful for function call chains, like +rect.fill('#333').rotate(30)+ and such
      class << self
        def chainable(*methods)
          methods.each do |method|
            self.class_eval <<-CODE
              alias _chainable_#{method} #{method}
              def #{method}(*args, &block)
                _chainable_#{method}(*args, &block)
                return self
              end
            CODE
          end
        end
      end

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
      end

      # Wrapper for the _rotate_ method of raphael.
      # The +absolute+ parameter indicates if the angle is absolute or relative to the
      # current one. The +mode+ parameters can be +:degrees+, which converts the
      # specified +angle+ into degrees properly
      def rotate(angle, absolute = true, mode = :degrees)
        if mode == :radians
          unless angle.kind_of? Numeric
            raise TypeError("#{angle} should be numeric if using with :radians mode")
          end
          angle = radians_to_degrees(angle)
        end
        @canvas << js_method('rotate', angle, !!absolute)
      end

      # Wrapper for the +translate+ method of raphael.
      # Accepts a delta x and a delta y
      def translate(dx, dy)
        @canvas << js_method('translate', dx, dy)
      end

      # Wrapper for the +scale+ method of raphael.
      def scale(scaleX, scaleY)
        @canvas << js_method('scale', scaleX, scaleY)
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
        @canvas << js_method('attr', {attribute => value})
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
        @canvas << js_method('toFront')
      end

      # Wrapper for the +toBack+ method of raphael
      def to_back
        @canvas << js_method('toBack')
      end

      chainable :apply_attributes, :attr
      chainable :rotate, :scale, :translate
      chainable :to_front, :to_back

      private
      def js_method(methodname, *args)
        "#{@name}.#{methodname}(#{args.map(&:to_json).join(', ')});"
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

    # Represents the _path_ object in raphael
    class Path < BasicShape

      def initialize(canvas, attributes_or_path = {}, path = nil, &block)
        puts "Initializing path #{self}!"
        if attributes_or_path.kind_of? String
          path = attributes_or_path
          options = {}
          super(canvas)
        elsif attributes_or_path.kind_of? Hash
          options = attributes_or_path
          super(canvas, options)
        else
          raise BadConstructorException("Second parameter should be either string or hash")
        end
        path_str = path ? "" : ", #{path.to_json}"
        @canvas << "var #{@name} = #{@canvas.name}.path({}#{path_str});"
        apply_attributes(options)
        #yield self if block_given?
        self.instance_eval(&block) if block_given?
      end

      # Wrapper for the +relatively+ method of raphael
      def relatively
        @canvas << js_method('relatively')
      end

      # Wrapper for the +absolutely+ method of raphael
      def absolutely
        @canvas << js_method('absolutely')
      end

      # Wrapper for the +moveTo+ method of raphael for path drawing
      def move_to(x, y)
        @canvas << js_method('moveTo', x, y)
      end
      
      # Wrapper for the +lineTo+ method of raphael for path drawing
      def line_to(x, y)
        @canvas << js_method('lineTo', x, y)
      end

      # Wrapper for the +cplineTo+ method of raphael for path drawing
      def cpline_to(x, y, width)
        @canvas << js_method('cplineTo', x, y, width)
      end
      
      # Wrapper for the +curveTo+ method of raphael for path drawing
      def curve_to(x1, y1, x2, y2, x3, y3)
        @canvas << js_method('curveTo', x1, y1, x2, y2, x3, y3)
      end

      # Wrapper for the +qcurveTo+ method of raphael for path drawing
      def qcurve_to(x1, y1, x2, y2)
        @canvas << js_method('qcurveTo', x1, y1, x2, y2)
      end

      # Wrapper for the +addRoundedCorner+ method of raphael for path drawing
      def rounded_corner(radius, direction)
        valid_directions = %w{lu ld ru rd ur ul dr dl}
        raise TypeError("direction should be a string") unless direction.kind_of? String
        unless valid_directions.include? direction
          raise ArgumentError("#{direction.inspect} is not a valid parameter #{valid_directions}")
        end
        @canvas << js_method('addRoundedCorner', radius, direction)
      end

      # Wrapper for the +andClose+ method of raphael for path drawing
      def and_close
        @canvas << js_method('andClose')
      end

      def method_missing(name, *args, &block)   #:nodoc:
        if name.to_s =~ /^(lu|ld|ru|rd|ur|ul|dr|dl)_corner$/
          rounded_corner(args[0], $1) 
            # In Ruby 1.9 one could call rc(*args, radius)
        else
          super(name, *args, &block)
        end
      end

      # Define chainable methods and aliases
      chainable :absolutely, :relatively
      chainable :move_to, :line_to, :cpline_to, :curve_to, :qcurve_to
      chainable :rounded_corner, :and_close
      alias to move_to
      alias line line_to
      alias curve curve_to
      alias rel relatively
      alias abs absolutely
      alias wave_to cpline_to
      alias rc rounded_corner
      alias close and_close

    end

  end
end
