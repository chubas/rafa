module Rafa
  module Elements
    
    class JavascriptLiteral
      attr_accessor :js
      def initialize(js)
        @js = js
      end
      
      def to_json(repr = nil)
        @js.to_s
      end
    end
    
    def js_literal(js)
      JavascriptLiteral.new(js)
    end
    
  end
end