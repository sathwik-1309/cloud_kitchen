class ApplicationError < StandardError
  attr_reader :status, :error, :message

  def initialize(message: nil, status: 400, error: nil)
    @message = message || 'Something went wrong'
    @status = status
    @error = error || 'application_error'
    super(@message)
  end
end
