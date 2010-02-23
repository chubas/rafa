require File.dirname(__FILE__) + '/raphael_element'

module Rafa
  module Elements

    # Represents the _set_ object in raphael
    # See http://raphaeljs.com/reference.html#set
    class Set < RaphaelElement

      # Yields an array, in which all elements that form part of the set should be added, usually via the
      # << method.
      def initialize(canvas, options = {}, &block)
        super(canvas, options)
        @elements = []
        yield @elements
        @canvas << "var #{@name} = #{@canvas.name}.set();"
        @elements.each do |element|
          raise "Set must receive RaphaelElement arguments" unless element.kind_of? RaphaelElement
        end
        @canvas << "#{@name}.push(#{@elements.map(&:name).join(', ')});"
        apply_attributes(options)
      end

    end

  end
end