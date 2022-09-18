# frozen_string_literal: true

FactoryBot.define do
  factory :post do
    association :user
    content { Faker::Lorem.sentence(word_count: rand(1...20)) }
  end
end
