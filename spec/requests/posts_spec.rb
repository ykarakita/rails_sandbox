# frozen_string_literal: true

require "rails_helper"

RSpec.describe "PostsController", type: :request do
  describe "GET #index" do
    subject { get posts_path }

    let!(:posts) { FactoryBot.create_list(:post, 3) }

    it do
      subject
      expect(response.status).to eq 200
    end

    it do
      subject
      sorted_posts = posts.sort_by(&:created_at).reverse
      expect(JSON.parse(response.body)).to match(sorted_posts.map { PostSerializer.new(_1).serializable_hash })
    end
  end
end
