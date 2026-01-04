# frozen_string_literal: true
# rubocop:todo all

module Mongoid

  # Adds type-casting behavior to Mongoid::Boolean class.
  class Boolean

    class << self

      # # Turn the object from the ruby type we deal with to a Mongo friendly
      # # type.
      # #
      # # @example Mongoize the object.
      # #   Boolean.mongoize("123.11")
      # #
      # # @return [ true | false | nil ] The object mongoized or nil.
      # def mongoize(object)
      #   return if object.nil?
      #   if object.to_s =~ (/\A(true|t|yes|y|on|1|1.0)\z/i)
      #     true
      #   elsif object.to_s =~ (/\A(false|f|no|n|off|0|0.0)\z/i)
      #     false
      #   end
      # end

      # [XPAND]: In Mongoid 8 if a Boolean field is set to an empty string it will be set to nil
      #
      # https://www.mongodb.com/docs/mongoid/current/release-notes/mongoid-8.0/#mongoid-criteria-cache-removed
      # https://github.com/mongodb/mongoid/blob/master/lib/mongoid/extensions/boolean.rb
      #
      # Mongoid < 8:
      #   FormField.new(approver_field: '').approver_field => false
      # Mongoid >= 8:
      #   FormField.new(approver_field: '').approver_field => nil
      #
      # This patch updates the false condition regex to include ^$ to match against empty strings. This is an issue
      # for the FormBuilder as false values for radio buttons can be passed as an empty string.
      #
      def mongoize(object)
        return if object.nil?

        if object.to_s&.match?(/\A(true|t|yes|y|on|1|1.0)\z/i)
          true
        elsif object.to_s&.match?(/\A(^$|false|f|no|n|off|0|0.0)\z/i)
          false
        end
      end
      alias :demongoize :mongoize
    end
  end
end
