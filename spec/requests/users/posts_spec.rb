# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Users::PostsController" do
  describe "GET #index" do
    subject { get user_posts_path(user_id: user.id) }

    let!(:user) { FactoryBot.create(:user) }
    let!(:posts) { FactoryBot.create_list(:post, 3, user:) }

    it do
      subject
      expect(response.status).to eq 200
    end

    it do
      subject
      sorted_posts = posts.sort_by(&:created_at).reverse
      expect(JSON.parse(response.body, symbolize_names: true)).to match(sorted_posts.map { PostSerializer.new(_1).as_json })
    end
  end
end
