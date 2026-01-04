# frozen_string_literal: true
# rubocop:todo all

module Xpand
  class Task
    include Mongoid::Document

    field :title, type: String

    belongs_to :xpand_module,
      class_name: 'Xpand::Module',
      inverse_of: :xpand_tasks

    validates :module, associated: true
    validates :title,  presence: true
  end
end
