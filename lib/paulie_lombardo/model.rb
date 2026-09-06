# frozen_string_literal: true

module PaulieLombardo
  # Adds 'has_paulie_notes' association to ActiveRecord models
  module Model
    extend ActiveSupport::Concern

    class_methods do
      # rubocop:disable-next Naming/PredicatePrefix
      def has_paulie_notes(interval: nil)
        class_attribute :paulie_notes_options, default: {}
        self.paulie_notes_options = { interval: interval }.freeze

        has_many :paulie_notes, as: :noteable, dependent: :delete_all
      end
    end
  end
end
