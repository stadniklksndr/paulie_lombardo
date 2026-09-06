# frozen_string_literal: true

require "rails/generators/active_record"

module PaulieLombardo
  module Generators
    # Creating the migration file for the paulie_notes table.
    class ActiveRecordGenerator < Rails::Generators::Base
      # Provides ActiveRecord implementation of #next_migration_number for #migration_template
      include ::ActiveRecord::Generators::Migration

      argument :tables, type: :array, default: []

      source_root File.join(File.dirname(__FILE__), "templates")

      def validate_tables_exist
        return if tables.empty?

        connection = ActiveRecord::Base.connection

        tables.each do |table_name|
          name = table_name.tableize

          unless connection.table_exists?(name)
            msg = set_color("Error: Table '#{name}' does not exist in the database.", :red, :bold)
            raise Thor::Error, msg
          end
        end
      end

      def create_migration_file
        migration_template "create_paulie_notes_table.rb.erb", "db/migrate/create_paulie_notes.rb"
      end

      def add_counter_cache_fields_to_tables
        return if tables.empty?

        migration_template "add_paulie_notes_count_to_tables.rb.erb", "db/migrate/add_paulie_notes_count.rb"
      end
    end
  end
end
