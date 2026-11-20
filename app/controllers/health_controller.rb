class HealthController < ActionController::Base
  def show
    ActiveRecord::Base.with_connection { |connection| connection.select_value("SELECT 1") }
    head :ok
  rescue ActiveRecord::ConnectionNotEstablished, ActiveRecord::StatementInvalid
    head :service_unavailable
  end
end
