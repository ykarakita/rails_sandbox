# frozen_string_literal: true

RSpec.describe PostSerializer, type: :serializer do
  let(:instance) { described_class.new(post) }
  let!(:post) { FactoryBot.create(:post, user:) }
  let!(:user) { FactoryBot.create(:user) }

  it do
    expect(instance.serializable_hash).to eq({
                                               "id" => post.id,
                                               "content" => post.content,
                                               "user" => UserSerializer.new(user).serializable_hash,
                                             })
  end
end
