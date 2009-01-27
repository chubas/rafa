require 'canvas/attributes'

module Rafa
  module Elements

    class BasicShape
      
      include Rafa::Elements::Attributes
      
      attr_accessor :canvas, :name

      def initialize(canvas, options = {})
        @canvas = canvas
        given_name = options.delete('id') || options.delete(:id)
        suffix = Time.now.to_i.to_s
        classname = self.class.to_s.split("::").last.downcase
        @name = given_name || "_raphael_#{classname}_#{suffix}"
      end

      def apply_attributes(attributes)
        attributes.each { |k, v| self[k] = v }
      end

      def rotate(angle, absolute = true, mode = :degrees)
        if mode == :radians
          angle = radians_to_degrees(angle)
        end
        @canvas << "#{@name}.rotate(#{angle}, #{!!absolute});"
      end

      def translate(dx, dy)
        @canvas << "#{@name}.translate(#{dx}, #{dy})"
      end

      def scale(scaleX, scaleY)
        @canvas << "#{@name}.scale(#{scaleX}, #{scaleY})"
      end

      def scale_x(x)
        @canvas << "#{@name}.scale(#{x}, 1)"
      end

      def scale_y(y)
        @canvas << "#{@name}.scale(1, #{y})"
      end

      # FIXME: This doesn't really belong here
      def radians_to_degrees(radians)
        return radians * (180 / Math::PI)
      end

      def []=(attribute, value)
        attribute = attribute.to_s.gsub(/[^a-zA-Z0-9_\-]/, '')
        unless POSSIBLE_ATTRIBUTES.include? attribute
          puts "Warning! Attribute #{attribute} not recognized"
          return nil
        end
        @canvas << "#{@name}.attr({#{attribute.inspect}:#{value.inspect}})"
        return self
      end
      
      def attr(name, value)
        self[name] = value
      end

      def method_missing(name, *args, &block)
        # FIXME: In case of returning nil
        if attr(name, args[0])
          self
        else
          super(name, *args, &block)
        end
      end

    end

    class Circle < BasicShape
      def initialize(canvas, center_x, center_y, radius, options = {})
        super(canvas, options)
        @canvas << "var #{@name} = #{@canvas.name}.circle(#{center_x}, #{center_y}, #{radius});"
        apply_attributes(options)
      end
    end

    class Rect < BasicShape
      def initialize(canvas, topleft_x, topleft_y, width, height, options = {})
        rounded = options.delete('rounded') || options.delete(:rounded) || 0
        super(canvas, options)
        @canvas << <<-JS
          var #{@name} = #{@canvas.name}.rect(
            #{topleft_x}, #{topleft_y},
            #{width}, #{height},
            #{rounded}
          );
        JS
      apply_attributes(options)
      end
    end

    class Ellipse < BasicShape
      def initialize(canvas, center_x, center_y, radius_x, radius_y, options = {})
        super(canvas, options)
        @canvas << <<-JS
          var #{@name} = #{@canvas.name}.ellipse(
            #{center_x}, #{center_y},
            #{radius_x}, #{radius_y}
          )
        JS
        apply_attributes(options)
      end
    end

    class Text < BasicShape
      def initialize(canvas, x, y, text, options = {})
        super(canvas, options)
        @canvas << <<-JS
          var #{@name} = #{@canvas.name}.text(
            #{x}, #{y}, #{text.inspect}
          )
        JS
        apply_attributes(options)
      end
    end

  end
end
