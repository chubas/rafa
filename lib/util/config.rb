require 'ostruct'

module Rafa

  CONFIG = OpenStruct.new
  CONFIG.raphael_version = '1.3.1'

  # Override if you want to define a custom uid generator.
  # It should respond to the <em>call</em> method, without parameters.
  CONFIG.generate_uid = Proc.new do
    "#{(Time.now.to_i).to_i.to_s}_#{rand(10_000)}"
  end

end