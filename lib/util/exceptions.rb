module Rafa
  module Util
    module Exceptions

      # Thrown when passed bad parameters for Canvas initialization
      class BadConstructorException < Exception
        def initialize(badargs)
          super("#{badargs} expected to be integers")
        end
      end
    end
  end
end
