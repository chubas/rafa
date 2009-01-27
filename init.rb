require 'rafa'

ActionView::Base.module_eval do
  include Rafa::Elements
end
