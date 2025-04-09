require 'rails_helper'

RSpec.describe Customer, type: :model do
  describe 'validations' do
    it 'is valid with valid attributes' do
      customer = Customer.new(name: 'Alice', email: 'alice@example.com')
      expect(customer).to be_valid
    end

    it 'is invalid without a name' do
      customer = Customer.new(name: nil, email: 'alice@example.com')
      expect(customer).not_to be_valid
      expect(customer.errors[:name]).to include("can't be blank")
    end

    it 'is invalid without an email' do
      customer = Customer.new(name: 'Alice', email: nil)
      expect(customer).not_to be_valid
      expect(customer.errors[:email]).to include("can't be blank")
    end

    it 'is invalid with a malformed email' do
      customer = Customer.new(name: 'Alice', email: 'not-an-email')
      expect(customer).not_to be_valid
      expect(customer.errors[:email]).to include("is invalid")
    end

    it 'is invalid with a duplicate email' do
      Customer.create!(name: 'Original', email: 'duplicate@example.com')
      dup = Customer.new(name: 'New', email: 'duplicate@example.com')
      expect(dup).not_to be_valid
      expect(dup.errors[:email]).to include("has already been taken")
    end
  end

  describe 'associations' do
    it 'has many orders' do
      assoc = described_class.reflect_on_association(:orders)
      expect(assoc.macro).to eq :has_many
      expect(assoc.options[:dependent]).to eq :destroy
    end
  end
end