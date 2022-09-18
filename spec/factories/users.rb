# frozen_string_literal: true

FactoryBot.define do
  factory :user do
    first_name { Faker::Name.first_name }
    last_name { Faker::Name.last_name }
    email { Faker::Internet.email(name: "#{first_name} #{last_name}", separators: ["-"]) }
    age { rand(0...100) }
  end
end
