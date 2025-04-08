class ValidationError < ApplicationError
  def initialize(message: nil, error_code: 422)
    super(message: message || 'Validation failed', status: error_code, error: 'validation_error')
  end
end
