# config/initializers/cors.rb

Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins lambda { |source, _env|
      # Allow localhost and any GitHub Codespaces URL
      source == 'http://localhost:3000' || source.match?(/^https:\/\/.*\.app\.github\.dev$/)
    }
    resource '*',
      headers: :any,
      methods: [:get, :post, :put, :patch, :delete, :options, :head],
      credentials: true
  end
end