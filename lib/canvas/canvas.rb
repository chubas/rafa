require File.dirname(__FILE__) + '/../util/util'
require File.dirname(__FILE__) + '/javascript_literal'
Dir[File.dirname(__FILE__) + '/elements/*.rb'].each do |element_file|
  require element_file
end

module Rafa
  module Elements
   
    # Creates a new +Canvas+ element, yields it and returns the
    # resulting javascript for the block call if the parameter <em>:wrap</em> is passed.
    # See {Raphael documentation}[http://raphaeljs.com/reference.html#Raphael] for more info
    def canvas(*args, &block)
      if args.last.kind_of?(Hash)
        options = args.pop
      else
        options = {}
      end

      yield paper = Canvas.new(*args) 
      
      wrap_in_script_tag = options.delete(:wrap) || true
      if wrap_in_script_tag
        javascript_tag(paper.contents.join("\n"))
      else
        paper.contents.join("\n")
      end
    end
    
    # Class that represents the raphael +canvas+ element.
    class Canvas

      include Rafa::Util

      attr_accessor :dom_element, :contents, :name, :width, :height

      # Initializes the canvas element. It takes the same parameters as the raphael
      # <em>canvas</em> element: four integers representing starting point, width and height,
      # or a string and two integers, representing the id of the DOM holder, width and height
      # See {Raphael documentation}[http://raphaeljs.com/reference.html#Raphael] for more info
      #--
      # TODO: Add support for attribute-value passing on initialization (third initialization method)
      #++
      def initialize(*args)
        is_integer = Proc.new{|i| i.kind_of? Integer or i.kind_of? JavascriptLiteral}
        if args[0].kind_of? Symbol or args[0].kind_of? String or args[0].kind_of? JavascriptLiteral
          @dom_element = args[0].to_s
          unless args[1, 2].all?(&is_integer)
            raise TypeError.new("Arguments #{args[1, 2].join(',')} expected to be integers")
          end
          @width, @height = args[1, 2]
          raphael_arguments = args[0, 3]
        else
          unless args[0, 4].all?(&is_integer)
            raise TypeError.new("Arguments #{args[0, 4].join(',')} expected to be integers")
          end
          @width, @height = args[2, 2]
          raphael_arguments = args[0, 4]
        end
        constructor = "new Raphael(#{raphael_arguments.to_js_args})"
        @contents = []
        @name = "rafa_canvas_" + Rafa::CONFIG.generate_uid.call
        self << "var #{@name} = #{constructor};"
      end

      # Generates a +Circle+ object
      # See Rafa::Elements::Circle
      def circle(*args)
        Rafa::Elements::Circle.new(self, *args)
      end

      # Generates a +Rect+ object
      # See Rafa::Elements::Rect
      def rect(*args)
        Rafa::Elements::Rect.new(self, *args)
      end

      # Generates an +Ellipse+ object
      # See Rafa::Elements::Ellipse
      def ellipse(*args)
        Rafa::Elements::Ellipse.new(self, *args)
      end

      # Generates a +Text+ object
      # See Rafa::Elements::Text
      def text(*args)
        Rafa::Elements::Text.new(self, *args)
      end
      
      # Generates a +Path+ object
      # See Rafa::Elements::Path
      def path(*args, &block)
        Rafa::Elements::Path.new(self, *args, &block)
      end

      # Generates an +Image+ object
      # See Rafa::Elements::Image
      def image(*args)
        Rafa::Elements::Image.new(self, *args)
      end

      # Generates a +Set+ object
      # See Rafa::Elements::Set
      def set(*args, &block)
        Rafa::Elements::Set.new(self, *args, &block)
      end

      # Utility method for building path strings, without generating a +Path+ object.
      # See Rafa::Elements::PathBuilder
      def build_path(initial_path = '', &block)
        path_builder = PathBuilder.new(initial_path)
        path_builder.instance_eval(&block)
        path_builder.result
      end

      # Injects a string directly into javascript output.
      # Used by elements to output its generation code, or can be used externally to
      # inject external javascript code
      def << js
        raise TypeError("String required") unless js.kind_of? String
        @contents << js
      end

    end
    
  end
end
