# frozen_string_literal: true

module PaulieLombardo
  module Generators
    # Stub generator for Mongoid ORM implementation
    class MongoidGenerator < Rails::Generators::Base
      def create_migration_file
        say_status :warning, "Mongoid support requires implementation for paulie_lombardo.", :yellow
        say "   Currently, automatic document/migration generation for Mongoid is not supported.", :yellow
      end
    end
  end
end
