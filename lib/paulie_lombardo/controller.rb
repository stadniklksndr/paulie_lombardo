# frozen_string_literal: true

module PaulieLombardo
  # Adds controller methods
  module Controller
    # Creates a new paulie_note record
    def paulie_note(*target)
      PaulieLombardo.bouncer(self, *target) do |target, data|
        target.paulie_notes.create!(data)
      end
    end
  end
end
