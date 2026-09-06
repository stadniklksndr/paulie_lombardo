# frozen_string_literal: true

FactoryBot.define do
  factory :question do
    sequence(:title) { |n| "Test Question Title #{n}" }
  end
end
