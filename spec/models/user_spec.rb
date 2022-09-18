# frozen_string_literal: true

require "rails_helper"

RSpec.describe User, type: :model do
  describe "validation" do
    subject { FactoryBot.build(:user) }

    it { is_expected.to validate_presence_of :first_name }
    it { is_expected.to validate_presence_of :last_name }
    it { is_expected.to validate_presence_of :age }
    it { is_expected.to validate_presence_of :email }
    it { is_expected.to validate_uniqueness_of(:email).ignoring_case_sensitivity }
  end
end
