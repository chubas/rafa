require 'canvas/elements'

module Rafa
  module Elements
    
    def canvas(*args, &block)
      c = Canvas.new(*args, &block)
      yield c
      concat(javascript_tag(
          "var #{c.name} = #{c.constructor};\n" +
          c.contents.join("\n")
      ))
    end
    
    class Canvas
      attr_accessor :dom_element, :contents, :name

      def initialize(*args, &block)
        if args[0].kind_of? Symbol or args[0].kind_of? String
          @dom_element = args[0]
          raise "Bad arguments" unless args[1, 2].all? {|a| a.kind_of? Integer}
            #TODO Raise an adequate exception
          @width, @height = args[1, 2]
          raphael_arguments = args[0, 3]
        else
          raise "Bad arguments" unless args[0, 4].all? {|a| a.kind_of? Integer}
            #TODO Raise an adequate exception
          @width, @height = args[2, 2]
          raphael_arguments = args[0, 4]
        end
        @constructor_args = raphael_arguments.map(&:inspect).join(",")
          
        @contents = []
        @name = "_raphael_canvas_" + Time.now.to_i.to_s
      end

      def constructor
        "new Raphael(#{@constructor_args})"
      end

      def method_missing(name, *args, &block)
        if name.to_s =~ /circle|rect|ellipse|text/ #FIXME
          puts "Sending #{name} with args #{args.inspect}"
          eval("Rafa::Elements::" + name.to_s.capitalize).new(self, *args)
        else
          super(name, *args, &block)
        end
      end

      def << script
        @contents << script
      end
    end
    
  end
end
