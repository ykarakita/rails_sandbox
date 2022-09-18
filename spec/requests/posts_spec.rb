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
      expect(JSON.parse(response.body, symbolize_names: true)).to match_array(posts.map { PostSerializer.new(_1).as_json })
    end
  end
end
