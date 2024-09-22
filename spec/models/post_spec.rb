# frozen_string_literal: true

RSpec.describe Post, type: :model do
  describe "validation" do
    subject { FactoryBot.build(:post) }

    it { is_expected.to validate_presence_of :content }
  end
end
