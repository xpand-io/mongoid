# frozen_string_literal: true
# rubocop:todo all

module Xpand
  class Module
    include Mongoid::Document

    field :title, type: String

    belongs_to :user

    has_many :xpand_tasks,
      inverse_of: :xpand_module,
      class_name: 'Xpand::Task'

    validates :user,  associated: true
    validates :title, presence: true

    accepts_nested_attributes_for :xpand_tasks
  end
end
