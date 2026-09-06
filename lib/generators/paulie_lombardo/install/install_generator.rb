# frozen_string_literal: true

module PaulieLombardo
  module Generators
    # Primary setup generator for installing the gem into a Rails app
    class InstallGenerator < Rails::Generators::Base
      argument :tables, type: :array, default: []

      # Invokes the configured ORM generator (e.g., ActiveRecord) to create migrations
      hook_for :orm, required: true
    end
  end
end
