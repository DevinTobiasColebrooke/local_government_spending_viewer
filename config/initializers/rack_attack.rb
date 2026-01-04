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

  # Limit search requests per IP to prevent AI server exhaustion
  # 30 searches per minute is generous for humans but blocks aggressive bots
  throttle("spending_search/ip", limit: 30, period: 1.minute) do |req|
    if req.path == "/spending_reports" && req.get?
      req.ip
    end
  end
end
