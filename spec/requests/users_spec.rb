# frozen_string_literal: true

require "rails_helper"

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
      expect(JSON.parse(response.body, symbolize_names: true)).to match_array(users.map { UserSerializer.new(_1).attributes })
    end
  end
end
