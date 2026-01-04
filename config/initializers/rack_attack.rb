class Rack::Attack
  # Throttle all requests by IP (300 requests per 5 minutes)
  throttle("req/ip", limit: 300, period: 5.minutes) do |req|
    req.ip
  end

  # Throttle login attempts
  throttle("logins/ip", limit: 5, period: 20.seconds) do |req|
    if req.path == "/session" && req.post?
      req.ip
    end
  end
end
