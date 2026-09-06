# frozen_string_literal: true

module PaulieLombardo
  # The decision-making authority that decides
  # whether a page view request should be approved and logged.
  class Consigliere
    def initialize(dossier)
      @dossier = dossier
    end

    def approve?
      no_prior_record?
    end

    private

    # Checks if there are no previous records for the given visitor.
    #
    # Automatically handles collision/fingerprint overlaps
    # multiple records with the same request_hash can coexist if they belong to different session_hashes
    #
    # @return [Boolean]
    #   true if no record exists and a new one should be created
    #   false if a record already exists
    def no_prior_record?
      # 1. Highest priority: if user is logged in, check purely by user_id
      return PaulieNote.where(@dossier.user_profile).none? if @dossier.user_id.present?

      # 2. If session_hash is blank, simply check existence via request_hash
      return PaulieNote.where(@dossier.request_profile).none? if @dossier.session_hash.blank?

      # 3. When session_hash present - returns false early if a matching record exists
      return false if PaulieNote.where(@dossier.session_profile).exists?

      # Finds a session-less record matching the request profile and links the current session_hash.
      return false if session_attached?

      true
    end

    def session_attached?
      note = PaulieNote.find_by(@dossier.request_profile)
      note&.update(session_hash: @dossier.session_hash)
    end
  end
end
