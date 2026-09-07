# frozen_string_literal: true

require_relative "lib/paulie_lombardo/version"

Gem::Specification.new do |spec|
  spec.name = "paulie_lombardo"
  spec.version = PaulieLombardo::VERSION

  spec.description = <<~TEXT
    Paulie Lombardo is a simple, lightweight Ruby on Rails page view counter.
  TEXT

  spec.homepage = "https://github.com/stadniklksndr/paulie_lombardo"

  spec.license = "MIT"

  spec.author = "Sasha Stadnyk"
  spec.email = "stadniklksndr@gmail.com"

  spec.files = Dir["lib/**/*.rb"]

  spec.required_ruby_version = ">= 4.0"

  spec.add_dependency "rails", ">= 8.0.0"

  spec.metadata["rubygems_mfa_required"] = "true"

  spec.metadata["source_code_uri"] = "https://github.com/stadniklksndr/paulie_lombardo"
  spec.metadata["changelog_uri"] = "https://github.com/stadniklksndr/paulie_lombardo/blob/master/CHANGELOG.md"

  spec.summary = <<~TEXT
    Records each view in the database and provides a simple way
    to track how many times a resource has been viewed.
  TEXT
end
