# frozen_string_literal: true

FactoryBot.define do
  factory :post do
    sequence(:title) { |n| "Test Post Title #{n}" }
    body { "Lorem ipsum dolor sit amet, consectetur adipiscing elit." }
  end
end
