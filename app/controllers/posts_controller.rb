# frozen_string_literal: true

class PostsController < ApplicationController
  def index
    posts = Post.includes(:user).order(created_at: :desc).page(params[:page]).per(params[:per])
    render json: posts
  end
end
