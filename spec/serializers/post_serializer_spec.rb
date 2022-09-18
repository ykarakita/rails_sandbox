# frozen_string_literal: true

require "rails_helper"

RSpec.describe PostSerializer, type: :serializer do
  let(:instance) { described_class.new(post) }
  let!(:post) { FactoryBot.create(:post, user:) }
  let!(:user) { FactoryBot.create(:user) }

  it do
    expect(instance.as_json).to eq({
                                     id: post.id,
                                     content: post.content,
                                     user: UserSerializer.new(user).attributes,
                                   })
  end
end
