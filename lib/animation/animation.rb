require 'animation/javascript_literal'

module Rafa
  module Animation

    class AnimationProxy
      
      include Rafa::Elements::Attributes
      
      attr_accessor :element, :seconds, :instruction_chain, :callback
      def initialize(element, seconds = 0, attributes = {}, callback = nil)
        @element = element
        @seconds = seconds
        @callback = call_when_finished(callback) if callback
        @chained = nil
        @updatable_attributes = attributes
      end

      def << (js)
        raise "Parameter should be a javascript string" unless js.kind_of? String
        @element.canvas << js
      end
      
      def output
        function_str + "()"
      end
      
      def function_str
        cb = callback_function
        "(function() { " +
          "#{@element.name}.animate(" +
            "#{@updatable_attributes.to_json}, " +
            "#{seconds * 1000} " +
            (cb ? ', ' + cb : '') +
          ")" +
        "})"
      end
      
      def callback_function
        if @chained and @callback
          <<-FUNCTION.strip
            (
              function(){
                #{@chained.function_str}();
                #{@callback}();
              }
            )
         FUNCTION
        elsif @chained
          @chained.function_str
        else
          @callback
        end
      end
      
      def call_when_finished(js)
        @callback = "(function() { #{js} })"
      end
      
      def after(seconds, attributes = {}, callback = nil)
        new_proxy = AnimationProxy.new(@element, seconds, attributes, callback)
        yield new_proxy
        @chained = new_proxy
      end
      
      def attr(attribute, value)
        attribute = attribute.to_s.gsub(/[^a-zA-Z0-9_\-]/, '')
        unless POSSIBLE_ATTRIBUTES.include? attribute
          puts "Warning! Attribute #{attribute} not recognized"
          return nil
        end
        @updatable_attributes[attribute] = value
        return self
      end
      
      # Special cases
      def translate(dx, dy)
        attr('translation', [dx, dy].join(','))
      end
      
      def scale(x, y)
        attr('scale', [x,y].join(','))
      end
      
      def rotate(angle)
        attr('rotation', angle)
      end
      
      def method_missing(name, *args, &block)
        puts "Calling method missing #{name} on #{self}"
        if attr(name, args[0])
          return self
        else
          super(name, *args, &block)
        end
      end
      
    end

    def animate(seconds, attributes = {}, callback = nil)
      if block_given?
        proxy = AnimationProxy.new(self, seconds, attributes, callback)
        yield proxy
        @canvas << proxy.output
      else
        time = (seconds * 1000).to_i
        callback_str = callback ? ", #{callback}" : ''
        attr = attributes.to_json
        @canvas << "#{@name}.animate(#{attr}, #{time} #{callback_str});"
      end
    end

    def every(seconds)
        anim_proxy = AnimationProxy.new(self, seconds, {})
        yield anim_proxy
        @canvas << <<-LOOP
          (
            function() {
              #{anim_proxy.output};
              setTimeout(arguments.callee, #{seconds * 1000});
            }
          )();
        LOOP
      end
    
  end
end

Rafa::Elements::BasicShape.class_eval do
  include Rafa::Animation
end
