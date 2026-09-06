# frozen_string_literal: true

require "bundler/setup"
require "pry"

require "active_record"
require "rails"
require "paulie_lombardo"
require "factory_bot"

# Set up an in-memory SQLite database connection for fast spec execution
ActiveRecord::Base.establish_connection(
  adapter: "sqlite3",
  database: ":memory:"
)

# Creates the temporary database tables needed to support spec models
ActiveRecord::Schema.define do
  create_table :users, force: true do |t|
    t.string :name
    t.timestamps
  end

  create_table :posts, force: true do |t|
    t.string :title
    t.text :body
    t.integer :paulie_notes_count, default: 0, null: false
    t.timestamps
  end

  create_table :questions, force: true do |t|
    t.string :title
    t.integer :paulie_notes_count, default: 0, null: false
    t.timestamps
  end

  create_table :paulie_notes, force: true do |t|
    t.string "noteable_id", null: false
    t.string "noteable_type", null: false
    t.string :session_hash
    t.string :request_hash, null: false
    t.references :user, foreign_key: true, null: true, index: false
    t.text :referrer
    t.date :viewed_on, null: false
    t.timestamps
  end
end

ActiveRecord::Base.include(PaulieLombardo::Model)
class Post < ActiveRecord::Base
  has_paulie_notes
end

class Question < ActiveRecord::Base
  has_paulie_notes interval: :daily
end

class User < ActiveRecord::Base; end

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  # Roll back all database changes after each test to ensure test isolation
  config.around do |example|
    ActiveRecord::Base.transaction do
      example.run
      raise ActiveRecord::Rollback
    end
  end

  # Enables FactoryBot methods (e.g., build, create) directly without the FactoryBot prefix
  config.include FactoryBot::Syntax::Methods

  # Configures FactoryBot to find and load factory definitions from spec/factories before running tests
  config.before(:suite) do
    # Set the absolute path to the spec/factories directory
    FactoryBot.definition_file_paths = [File.expand_path("factories", __dir__)]

    # Load all factory definitions into FactoryBot before test execution
    FactoryBot.find_definitions
  end
end
