module Rafa
  module Util

    # Converts the specified radians to degrees
    def radians_to_degrees(radians)
      return radians * (180 / Math::PI)
    end

    # Generates a _supposedly_ unique id for using in naming javascript generated
    # variable names
    def uid_suffix
      (Time.now.to_i * rand).to_i.to_s
    end

  end
end
