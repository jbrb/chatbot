import Config

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :chatbot, ChatbotWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "hj5Pmq7PJPjgIN7O5ZrTnxBBbe7d4bXO6wdNeWeo4wJDM/YT0VvrhBRwMydP3Z6+",
  server: false

config :chatbot,
  webhook_token: "test_token",
  fb_access_token: "test_token",
  http_adapter: HttpAdapterMock

# Print only warnings and errors during test
config :logger, level: :warn

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime
