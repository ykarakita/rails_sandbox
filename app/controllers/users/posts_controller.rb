# frozen_string_literal: true

module Users
  class PostsController < ApplicationController
    def index
      user = User.find(params[:user_id])
      posts = user.posts.order(created_at: :desc).page(params[:page]).per(params[:per])
      render json: posts
    end
  end
end
