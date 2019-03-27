# module Checkout
#   module Model
#     def self.included(base)
#       base.send :extend, ClassMethods
#     end
#     module ClassMethods
#       def to_checkout_resource( data = {})
#         data
#       end
#     end
#   end
# end