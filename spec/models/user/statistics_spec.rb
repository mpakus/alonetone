# frozen_string_literal: true

require 'rails_helper'

RSpec.describe User::Statistics, type: :model do
  context 'user with published music' do
    let(:user) { users(:will_studd) }

    it 'returns number of listens per day since started publishing' do
      # This number may change when the number of listens in the users fixtures change.
      expect(user.listens_per_day).to eq(1)
    end
  end

  context 'user with published music and without listens' do
    let(:user) { users(:henri_willig) }

    it 'returns number of listens per day since started publishing' do
      expect(user.listens_per_day).to eq(0)
    end
  end

  context 'user without published music' do
    let(:user) { users(:jamie_kiesl) }

    it 'raises exception when trying to return number of listens per day' do
      expect do
        user.listens_per_day
      end.to raise_error(User::Statistics::Error)
    end
  end
end
