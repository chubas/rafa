require File.dirname(__FILE__) + '/raphael_element'

module Rafa
  module Elements

    # Represents the _path_ object in raphael
    # See http://raphaeljs.com/reference.html#path
    # If a block is passed, a PathBuilder object is passed and evaluated within instance context. The
    # resulting path is used as the path string for the path object.
    # Example:
    #
    #   canvas.path(attributes) do
    #     move_to(10, 10)
    #     line_to(50, 100).line_to(100, 50).and_close
    #   end
    class Path < RaphaelElement

      def initialize(canvas, attributes_or_path = '', options = nil, &block)
        if attributes_or_path.kind_of? String or attributes_or_path.kind_of? JavascriptLiteral
          initial_path = attributes_or_path
          options = {}
          super(canvas)
        elsif attributes_or_path.kind_of? Hash
          initial_path = ''
          options = attributes_or_path
          super(canvas, options)
        else
          raise TypeError.new("Second parameter should be either string or hash")
        end

        path_builder = PathBuilder.new(initial_path)
        
        path_builder.instance_eval(&block) if block_given?
        @canvas << "var #{@name} = #{@canvas.name}.path(#{path_builder.result.to_json});"
        apply_attributes(options)
      end
    end

    # Class holding methods for path construction, in svg path format.
    # Adapted from 0.8 branch of raphael.js, from {SVG Specification}[http://www.w3.org/TR/SVG/paths.html#PathData]
    # See Canvas#build_path and Rafa::Elements::Path
    class PathBuilder
      def initialize(initial_path = '')
        @initial_path = initial_path
        @path_builder = []
        @mode = :absolute
        @last = Struct.new(:x, :y, :bx, :by).new(0, 0, 0, 0)
      end

      # Switches to relative mode
      def relatively
        @mode = :relative
        return self
      end

      # Switches to absolute mode
      def absolutely
        @mode = :absolute
        return self
      end

      # Moves to the specified point <em>x</em>, <em>y</em>, without tracing a line.
      # See {SVG 'move to' command specification}[http://www.w3.org/TR/SVG/paths.html#PathDataMovetoCommands]
      def move_to(x, y)
        command = absolute? ? 'M' : 'm'
        args = [x, y]
        @path_builder << "#{command}#{to_path(args)}"
        @last.x = (absolute? ? 0 : @last.x) + x
        @last.y = (absolute? ? 0 : @last.y) + y
        return self
      end

      # Draws a line to the specified point <em>x</em>, <em>y</em>.
      # See {SVG 'line to' command specification}[http://www.w3.org/TR/SVG/paths.html#PathDataLinetoCommands]
      def line_to(x, y)
        command = absolute? ? 'L' : 'l'
        args = [x, y]
        @path_builder << "#{command}#{to_path(args)}"
        @last.x = (absolute? ? 0 : @last.x) + x
        @last.y = (absolute? ? 0 : @last.y) + y
        return self
      end

      # Draws an arc to the specified point <em>x</em>, <em>y</em>, with the
      # radii <em>rx</em>, <em>ry</em>, rotation <em>x_rotation</em> and <em>large_arc_flag</em>
      # and <em>sweep_flag</em> flag parameters.
      # See {SVG 'arc' command specification}[http://www.w3.org/TR/SVG/paths.html#PathDataEllipticalArcCommands]
      def arc_to(rx, ry, x_rotation, large_arc_flag, sweep_flag, x, y)
        args = [rx, ry, x_rotation, large_arc_flag, sweep_flag, x, y]
        command = absolute? ? 'A' : 'a'
        @path_builder << "#{command}#{to_path(args)}"
        @last.x = x
        @last.y = y
        return self
      end

      # Draws a cubic bezier curve to the specified point <em>x</em>, <em>y</em>.
      # See {SVG 'cubic bezier curve' command specification}[http://www.w3.org/TR/SVG/paths.html#PathDataCubicBezierCommands]
      def curve_to(x1, y1, x2, y2, x3 = nil, y3 = nil)
        args = [x1, y1, x2, y2, x3, y3].compact
        command = case args.size
          when 4 then absolute? ? 'S' : 's'
          when 6 then absolute? ? 'C' : 'c'
        end
        @path_builder << "#{command}#{to_path(args)}"
        @last.x = (absolute? ? 0 : @last.x) + args[-2]
        @last.y = (absolute? ? 0 : @last.y) + args[-1]
        @last.bx = args[-4]
        @last.by = args[-3]
        return self
      end

      # Draws a quadratic bezier curve to the specified point <em>x</em>, <em>y</em>.
      # See {SVG 'cubic bezier curve' command specification}[http://www.w3.org/TR/SVG/paths.html#PathDataQuadraticBezierCommands]
      def qcurve_to(x1, y1, x2 = nil, y2 = nil)
        args = [x1, y1, x2, y2].compact
        command = case args.size
          when 2 then absolute? ? 'T' : 't'
          when 4 then absolute? ? 'Q' : 'q'
        end
        @path_builder << "#{command}#{to_path(args)}"
        @last.x = (absolute? ? 0 : @last.x) + args[-2]
        @last.y = (absolute? ? 0 : @last.y) + args[-1]
        return self
      end

      # Draws a cubic bezier curve, following the line to the specified line (much in the form of a wave).
      # Auxiliar method ported from raphael 0.8 branch.
      def cpline_to(x, y, w = nil)
        return line_to(x, y) unless w
        command = absolute? ? 'C' : 'c'
        args = [@last.x + w, @last.y, x - w, y, x, y]
        @path_builder << "#{command}#{to_path(args)}"
        @last.x = (absolute? ? 0 : @last.x) + x
        @last.y = (absolute? ? 0 : @last.y) + y
        @last.bx = x - w
        @last.by = y
      end

      # Draw rounded corners in one of the following directions (<em>direction</em> parameter):
      # <em>lu, ld, ru, rd, ur, ul, dr, dl</em>, where the letters indicate the direction of the
      # corner (left, right, up and down).
      # It can be passed either as a string or a symbol.
      # Auxiliar method ported from raphael 0.8 branch.
      def rounded_corner(radius, direction)
        r = 0.5522 * radius
        old_mode, @mode = @mode, :relative
        case direction.to_s
          when 'lu' then curve_to(-r,  0,  -radius,      -(radius - r), -radius, -radius)
          when 'ld' then curve_to(-r,  0,  -radius,        radius - r,  -radius,  radius)
          when 'ru' then curve_to( r,  0,   radius,      -(radius - r),  radius, -radius)
          when 'rd' then curve_to( r,  0,   radius,        radius - r,   radius,  radius)
          when 'ur' then curve_to( 0, -r, -(r - radius),  -radius,       radius, -radius)
          when 'ul' then curve_to( 0, -r,   r - radius,   -radius,      -radius, -radius)
          when 'dr' then curve_to( 0,  r, -(r - radius),   radius,       radius,  radius)
          when 'dl' then curve_to( 0,  r,   r - radius,    radius,      -radius,  radius)
          else raise TypeError("Invalid rounded corner argument: #{direction}")
        end
        @mode = old_mode
        return self
      end

      # Closes the current path.
      # See {SVG 'close' command specification}[http://www.w3.org/TR/SVG/paths.html#PathDataClosePathCommand]
      def and_close
        @path_builder << 'z'
        return self
      end

      alias to        move_to
      alias line      line_to
      alias wave_to   cpline_to
      alias curve     curve_to
      alias qcurve    qcurve_to
      alias bezier_to qcurve_to
      alias bezier    qcurve_to
      alias rel       relatively
      alias abs       absolutely
      alias close     and_close
      alias arc       arc_to

      def result
        (@initial_path ? "#{@initial_path} " : '') + @path_builder.join(' ')
      end

      def method_missing?(name, *args, &block)
        if name.to_s =~ /^(lu|ld|ru|rd|ur|ul|dr|dl)_corner$/
          rounded_corner(args[0], $1)
        else
          super(name, *args, &block)
        end
      end

      private

        def absolute?
          return @mode == :absolute
        end

        def to_path_param(arg)
          case arg
            when String, Integer   then arg
            when Float             then "%0.3f" % arg
          end
        end

        def to_path(args)
          args.map{|arg| to_path_param(arg)}.join(' ')
        end

    end

  end
end
