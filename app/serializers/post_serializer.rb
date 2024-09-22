# frozen_string_literal: true

class PostSerializer
  include Alba::Resource

  attributes :id, :content

  one :user
end
