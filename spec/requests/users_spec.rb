# frozen_string_literal: true

RSpec.describe "UsersController", type: :request do
  describe "GET #index" do
    subject { get users_path }

    let!(:users) { FactoryBot.create_list(:user, 3) }

    it do
      subject
      expect(response.status).to eq 200
    end

    it do
      subject
      sorted_users = users.sort_by(&:created_at).reverse
      expect(JSON.parse(response.body)).to match(sorted_users.map { UserSerializer.new(_1).serializable_hash })
    end
  end
end
