# frozen_string_literal: true

class UsersController < ApplicationController
  def index
    users = User.order(created_at: :desc).page(params[:page]).per(params[:per])
    render json: users
  end
end
