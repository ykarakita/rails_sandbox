class User < ApplicationRecord
  validates :first_name, presence: true
  validates :last_name, presence: true
  validates :age, presence: true
  validates :email, presence: true, uniqueness: true
end
