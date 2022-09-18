# frozen_string_literal: true

class PostsController < ApplicationController
  def index
    res = Post.joins(:user).map { _1.attributes.merge(user: _1.user) }

    render json: res
  end
end
