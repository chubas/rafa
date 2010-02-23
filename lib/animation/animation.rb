require File.dirname(__FILE__) + '/../canvas/javascript_literal'
require File.dirname(__FILE__) + '/../canvas/attributes'
require File.dirname(__FILE__) + '/../canvas/elements/raphael_element'

module Rafa
  module Animation

    # Represents a proxy method for calling animations within it in an easy way, as well
    # as chaining animations.
    class AnimationProxy
      
      include Rafa::Elements::Attributes
      
      attr_accessor :element, :seconds, :instruction_chain, :callback

      # Holds <em>element</em> which is going to be animated in +seconds+ seconds,
      # the attributes to animate and the callback
      def initialize(element, seconds = 0, attributes = {}, callback = nil)
        @element = element
        @seconds = seconds
        @callback = call_when_finished(callback) if callback
        @chained = nil
        @updatable_attributes = attributes
      end

      # Injects javascript directly to the canvas element
      def << (js)
        @element.canvas << js
      end
      
      # Returns the function string <b>and calls it</b>. See function_str
      def output
        function_str + "()"
      end
      
      # Returns the javascript function string without being called.
      # Wraps it as an anonymous function object, and return it.
      # It is used internally, but may be used externally as well for posterior callback.
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
      
      # Returns the callback function for the animation.
      # If there is a chained animation, return its <em>function_str</em>,
      # if there is a defined callback, returns it, or if there are both,
      # returns them wrapped in another anonymous function.
      def callback_function
        if @chained and @callback
          <<-CODE
            (function(){
              #{@chained.function_str}();
              #{@callback}();
            })
          CODE
        elsif @chained
          @chained.function_str
        else
          @callback
        end
      end
      
      # Sets a custom callback function
      def call_when_finished(js)
        @callback = "(function() { #{js} })"
      end
      
      # Creates a new animation proxy, and concatenates its results to the callback function.
      # That is, after finishing the current animation, a new one is started.
      # It yields the new animation, just as the current one may be yielded by the +animate+ method.
      #--
      # Previously named +after+
      #++
      def chain(seconds, attributes = {}, callback = nil)
        new_proxy = AnimationProxy.new(@element, seconds, attributes, callback)
        yield new_proxy
        @chained = new_proxy
        return self
      end
      
      # Unlike <em>Node::attr</em> method, it does not directly updates the attribute,
      # rather puts it in a list and then calls all of them as parameters for the
      # raphael <em>animate</em> method.
      def attr(attribute, value)
        attribute = attribute.to_s.gsub(/[^a-zA-Z0-9_\-]/, '')
        # FIXME: Log, don't print
        unless POSSIBLE_ATTRIBUTES.include? attribute
          puts "Warning! Attribute #{attribute} not recognized"
          return nil
        end
        @updatable_attributes[attribute] = value
        return self
      end
      
      # Alias for <em>translation</em> animation attribute. Transforms the coordinates into csv
      def translate(dx, dy)
        attr('translation', [dx, dy].join(','))
      end
      
      # Alias for <em>translation</em> animation attribute. Transforms the coordinates into csv
      def scale(x, y)
        attr('scale', [x,y].join(','))
      end
      
      # Alias for <em>rotation</em> animation attribute
      def rotate(angle)
        attr('rotation', angle)
      end
      
      # Tries to call the <em>attr</em> method. If nil, it will continue with expected behavior.
      def method_missing(name, *args, &block)
        if attr(name, args[0])
          return self
        else
          super(name, *args, &block)
        end
      end
      
    end


    # Creates an <em>AnimationProxy</em> object, and:
    # * if a block is given, yields it. After the block call,
    #   it writes its output to the canvas output.
    # * if no block is given, just write the output for the
    #   passed parameters.
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

    # Creates a loop to be executed every <em>seconds<em> seconds. It yields
    # an <em>AnimationProxy</em> object, whose output is used as the body of the function to
    # be repeatedly called.
    def every(seconds)
        anim_proxy = AnimationProxy.new(self, seconds, {})
        yield anim_proxy
        @canvas <<
          "(function() {" +
              "#{anim_proxy.output};" +
              "setTimeout(arguments.callee, #{seconds * 1000});" +
          "})();"
      end
    
  end
end

Rafa::Elements::RaphaelElement.class_eval do
  include Rafa::Animation
end
