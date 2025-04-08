require 'rails_helper'

RSpec.describe 'Customers API', type: :request do
  include ActiveJob::TestHelper
  let!(:customers) { create_list(:customer, 5) }
  let(:customer_id) { customers.first.id }

  describe 'GET /customers' do
    it 'returns all customers' do
      get '/customers'
      expect(response).to have_http_status(200)
      expect(JSON.parse(response.body).size).to eq(5)
    end
  end

  describe 'GET /customers/:id' do
    context 'when valid' do
      it 'returns the customer' do
        get "/customers/#{customer_id}"
        expect(response).to have_http_status(200)
        expect(JSON.parse(response.body)['id']).to eq(customer_id)
      end
    end

    context 'when customer does not exist' do
      it 'returns 404' do
        get "/customers/0"
        expect(response).to have_http_status(404)
        expect(JSON.parse(response.body)).to eq({ "error" => "Customer not found" })
      end
    end
  end

  describe 'POST /customers' do
    context 'when valid' do
      before do
        allow(Mailer::WelcomeMailerWorker).to receive(:perform_async)
      end
    
      it 'creates a customer and enqueues the mailer worker' do
        expect {
          post '/customers', params: { customer: { name: 'Jane', email: 'jane@gmail.com' } }
        }.to change(Customer, :count).by(1)
    
        expect(response).to have_http_status(201)
    
        customer = Customer.last
    
        expect(Mailer::WelcomeMailerWorker).to have_received(:perform_async).with(customer.id)
      end
    end

    context 'when invalid (missing name)' do
      it 'returns 422 with errors' do
        post '/customers', params: { customer: { email: 'jane@gmail.com' } }
        expect(response).to have_http_status(422)
        expect(JSON.parse(response.body)).to have_key('errors')
      end
    end

    context 'when invalid (bad email)' do
      it 'returns 422 with error' do
        post '/customers', params: { customer: { name: 'Jane', email: 'janeemail' } }
        expect(response).to have_http_status(422)
        expect(JSON.parse(response.body)['errors']).to include("Email is invalid")
      end
    end
  end

  describe 'PUT /customers/:id' do
    it 'updates the customer' do
      put "/customers/#{customer_id}", params: { customer: { name: 'Updated Name' } }
      expect(response).to have_http_status(200)
      expect(JSON.parse(response.body)['name']).to eq('Updated Name')
    end
  end

  describe 'DELETE /customers/:id' do
    it 'deletes the customer' do
      expect {
        delete "/customers/#{customer_id}"
      }.to change(Customer, :count).by(-1)

      expect(response).to have_http_status(204)
    end
  end

  describe 'Middleware Error Rescue' do
    before do
      allow(Customer).to receive(:all).and_raise(StandardError.new("BOOM!"))
    end

    it 'returns 500 without exposing backtrace' do
      get '/customers'
      expect(response).to have_http_status(500)
      expect(JSON.parse(response.body)).to eq({ "error" => "Internal Server Error" })
    end
  end
end