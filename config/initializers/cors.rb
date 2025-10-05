# Be sure to restart your server when you modify this file.

# Avoid CORS issues when API is called from the frontend app.
# Handle Cross-Origin Resource Sharing (CORS) in order to accept cross-origin Ajax requests.

# Read more: https://github.com/cyu/rack-cors

Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    # Allow requests from the Vite dev server and production
    origins "http://localhost:5173",
            "http://localhost:3000",
            "http://localhost:3001",
            "http://localhost:3038",           # Soulforge dev server
            "https://jeremedia.com",
            "https://www.jeremedia.com"

    resource "*",
      headers: :any,
      methods: [:get, :post, :put, :patch, :delete, :options, :head],
      credentials: false  # Changed to false for API-only requests
  end
end