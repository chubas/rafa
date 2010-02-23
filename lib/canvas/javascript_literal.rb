module Rafa
  module Elements
    
    # Holds a javascript expression for printing later in code.
    # Used when some javascript is intended to be used as a parameter, because
    # a simple string passed is converted to a javascript string object internally.
    # e.g.
    # <tt>figure['rotation'] = js_literal('(new Date()).getSeconds()')</tt>
    #
    # see <em>javascript_literal</em>
    class JavascriptLiteral
      attr_accessor :js

      # Initializer with the javascript code printed directly to the output.
      def initialize(js)
        @js = js
      end

      # Returns the javascript literal expression      
      def to_json(repr = nil)
        @js.to_s
      end
    end
    
    # See JavascriptLiteral#new
    def js_literal(js)
      JavascriptLiteral.new(js)
    end
    
  end
end
