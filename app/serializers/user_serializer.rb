# frozen_string_literal: true

class UserSerializer
  include Alba::Resource

  attributes :id, :first_name, :last_name, :age, :email
end
