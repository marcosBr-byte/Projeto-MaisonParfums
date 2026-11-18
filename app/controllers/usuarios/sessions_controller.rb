class Usuarios::SessionsController < Devise::SessionsController
  rate_limit store: SecurityRateLimitStore, to: 20, within: 10.minutes, only: :create
end
