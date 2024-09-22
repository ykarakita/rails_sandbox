# frozen_string_literal: true

require "rails_helper"

RSpec.describe UserSerializer, type: :serializer do
  let(:instance) { described_class.new(user) }
  let!(:user) { FactoryBot.create(:user) }

  it do
    expect(instance.serializable_hash).to eq({
                                               "id" => user.id,
                                               "first_name" => user.first_name,
                                               "last_name" => user.last_name,
                                               "age" => user.age,
                                               "email" => user.email,
                                             })
  end
end
