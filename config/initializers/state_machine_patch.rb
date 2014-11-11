# The state_machine gem doesn't support Rails 4.1 out of the box.
# This patches stuff to work.
#
# See: https://github.com/pluginaweek/state_machine/issues/251
module StateMachine
  module Integrations
     module ActiveModel
        public :around_validation
     end

     module ActiveRecord
        public :around_save
     end
  end
end
module StateMachine
  module Integrations
     module ActiveModel
        public :around_validation
     end

     module ActiveRecord
        public :around_save
     end
  end
end
