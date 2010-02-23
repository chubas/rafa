require File.dirname(__FILE__) + '/../../util/util'
require File.dirname(__FILE__) + '/../../canvas/attributes'
require File.dirname(__FILE__) + '/../../canvas/boundingbox'
require File.dirname(__FILE__) + '/../../canvas/javascript_literal'

module Rafa
  module Elements

    # This class is the superclass for all canvas elements, such as
    # Circle, Rect, Ellipse, Text and Path
    class RaphaelElement

      include Rafa::Elements::Attributes
      include Rafa::Util

      attr_accessor :canvas, :name, :bbox

      # At initialization, it generates a unique variable name to identify this element
      # in the javascript. It can be passed in _options_ parameter with the key :id
      def initialize(canvas, options = {})
        @canvas     = canvas
        given_name  = options.delete('id') || options.delete(:id)
        suffix      = Rafa::CONFIG.generate_uid.call
        classname   = self.class.to_s.demodulize.downcase
        @name       = given_name || "rafa_#{classname}_#{suffix}"
      end

      # It applies the given attributes to the object.
      def apply_attributes(attributes)
        attributes.each { |k, v| self[k] = v }
        return self
      end

      # Wrapper for the _rotate_ method of raphael.
      # The +absolute+ parameter indicates if the angle is absolute or relative to the
      # current one. The +mode+ parameters can be +:degrees+, which converts the
      # specified +angle+ into degrees properly
      #--
      # TODO: Update documentation
      #++
      def rotate(angle, *params)
        absolute_or_coord = params[0] || true
        mode_or_coord     = params[1] || :degrees
        mode              = params[2] || :degrees

        if absolute_or_coord.kind_of? Numeric
          raise TypeError("Second and third arguments should be numeric if using coordinates") unless mode_or_coord.kind_of? Numeric
          if mode == :radians
            raise TypeError("#{angle} should be numeric if using with :radians mode") unless angle.kind_of? Numeric
            angle = radians_to_degrees(angle)
          end
          @canvas << js_method('rotate', angle, absolute_or_coord, mode_or_coord)
        else
          if mode_or_coord == :radians
            raise TypeError("#{angle} should be numeric if using with :radians mode") unless angle.kind_of? Numeric
            angle = radians_to_degrees(angle)
          end
          @canvas << js_method('rotate', angle, !!absolute_or_coord)
        end
        return self
      end

      # Wrapper for the +translate+ method of raphael.
      # Accepts a delta x and a delta y
      def translate(dx, dy)
        @canvas << js_method('translate', dx, dy)
        return self
      end

      # Wrapper for the +scale+ method of raphael.
      # Receives a +scale_x+ and +scale_y+ parameter, relative to 1.0, indicating
      # the scale percentage. Optionally accepts +center_x+ and +center_y+ paramenter,
      # which indicate the coordinates for the center of rotation point.
      def scale(scale_x, scale_y, center_x = nil, center_y = nil)
        args = [scale_x, scale_y, center_x, center_y].compact
        @canvas << js_method('scale', *args)
        return self
      end

      # Scales just the x component. See +:scale+
      def scale_x(x, center_x = nil, center_y = nil)
        scale(x, 1, center_x, center_y)
      end

      # Scales just the y component. See +:scale+
      def scale_y(y, center_x = nil, center_y = nil)
        scale(1, y, center_x, center_y)
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
        attribute = attribute.to_s.gsub(/[^a-zA-Z0-9_\-]/, '').gsub('_', '-')
        # FIXME => Attributes per class
        unless POSSIBLE_ATTRIBUTES.include? attribute
          # FIXME: Log, don't print
          puts "Warning! Attribute #{attribute} not recognized"
          @canvas << js_method('attr', {attribute => value})
          return nil
        end
        @canvas << js_method('attr', {attribute => value})
        return self
      end

      # Alias for +:[]+ method
      def attr(name, value)
        self[name] = value
        return self
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
        returning "#{@name}_node" do |nodename|
          @canvas << "var #{nodename} = #{@name}.node;"
        end
      end

      # Wrapper for +toFront+ method of raphael
      def to_front
        @canvas << js_method('toFront')
        return self
      end

      # Wrapper for the +toBack+ method of raphael
      def to_back
        @canvas << js_method('toBack')
        return self
      end

      private
      def js_method(methodname, *args)
        "#{@name}.#{methodname}(#{args.map(&:to_json).join(', ')});"
      end

    end

  end
end