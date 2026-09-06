# frozen_string_literal: true

FactoryBot.define do
  factory :paulie_note do
    noteable factory: %i[post]

    sequence(:session_hash) { |n| "session_hash_#{n}" }
    sequence(:request_hash) { |n| "request_hash_#{n}" }

    referrer { "https://example.com/page" }
  end
end
