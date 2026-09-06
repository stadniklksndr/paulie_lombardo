# frozen_string_literal: true

require "paulie_lombardo/paulie_static_page"
require "paulie_lombardo/dossier"
require "paulie_lombardo/controller"
require "paulie_lombardo/paulie_note"
require "paulie_lombardo/model"
require "paulie_lombardo/consigliere"
require "paulie_lombardo/railtie"

# Main entry point for the PaulieLombardo
module PaulieLombardo
  def self.bouncer(*)
    dossier = Dossier.new(*)
    consigliere = Consigliere.new(dossier)

    paulie_note = yield(dossier.target, dossier.data) if consigliere.approve?

    if paulie_note.present?
      paulie_note.noteable
    else
      dossier.target
    end
  end
end
