if Rails.env.development?
  Rails.application.middleware.use Oink::Middleware
end