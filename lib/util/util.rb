module Rafa
  module Util

    # Converts the specified radians to degrees
    def radians_to_degrees(radians)
      return radians * (180 / Math::PI)
    end

    module ArrayExtensions # :nodoc: all

      # Handy method to be able to pass arguments to a javascript function.
      # Differs from a simple +to_json+ by removing the enclosing brackets
      def to_js_args(separator = ', ')
        map(&:to_json).join(separator)
      end
    end

  end
end

class Array # :nodoc:

  # Monkeypatch Array class to include the method
  include Rafa::Util::ArrayExtensions

end
