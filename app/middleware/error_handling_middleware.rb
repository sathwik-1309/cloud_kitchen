class ErrorHandlingMiddleware
  def initialize(app)
    @app = app
  end

  def call(env)
    begin
      @app.call(env)
    rescue ActionController::ParameterMissing => e
      Rails.logger.error "[Parameter Missing] #{e.message}"
      [
        400,
        { 'Content-Type' => 'application/json' },
        [{ error: e&.message }.to_json]
      ]
    rescue StandardError => e
      Rails.logger.error "[Internal Server Error] #{e.class} - #{e.message}"
      Rails.logger.error e.backtrace.join("\n")

      [
        500,
        { 'Content-Type' => 'application/json' },
        [{ error: 'Internal Server Error' }.to_json]
      ]
    end
  end
end