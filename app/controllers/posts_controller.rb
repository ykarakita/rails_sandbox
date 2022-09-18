# frozen_string_literal: true

class PostsController < ApplicationController
  def index
    render json: Post.includes(:user)
  end
end
