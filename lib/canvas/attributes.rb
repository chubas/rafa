module Rafa
  module Elements
    module Attributes
      
      # Taken literally from http://raphaeljs.com/reference.html#attr
      POSSIBLE_ATTRIBUTES = [  
        'cx', # number
        'cy', # number
        'dasharray', # string [“-”, “.”, “-.”, “-..”, “. ”, “- ”, “--”, “- .”, “--.”, “--..”]
        'fill', # colour
        'fill-opacity', # number
        'font', # string
        'font-family', # string
        'font-size', # number
        'font-weight', # string
        'gradient', # object
        'height', # number
        'opacity', # number
        'path', # pathString
        'r', # number
        'rotation', # number
        'rx', # number
        'ry', # number
        'scale', # CSV
        'stroke', # colour
        'stroke-linecap', # string [“butt”, “square”, “round”, “miter”]
        'stroke-linejoin', # string [“butt”, “square”, “round”, “miter”]
        'stroke-miterlimit', # number
        'stroke-opacity', # number
        'stroke-width', # number
        'translation', # CSV
        'width', # number
        'x', # number
        'y' # number
      ]
      
    end
  end
end
