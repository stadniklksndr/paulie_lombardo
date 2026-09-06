# frozen_string_literal: true

module PaulieLombardo
  module Generators
    # Stub generator for Sequel ORM implementation
    class SequelGenerator < Rails::Generators::Base
      def create_migration_file
        say_status :warning, "Sequel support requires implementation for paulie_lombardo.", :yellow
        say "   Currently, automatic migration generation for Sequel is not supported.", :yellow
      end
    end
  end
end
