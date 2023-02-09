import Config

config :chatbot, ChatbotWeb.Endpoint,
  server: true,
  http: [port: {:system, "PORT"}], # Needed for Phoenix 1.2 and 1.4. Doesn't hurt for 1.3.
  url: [host: "crypto-fb-chatbot.gigalixirapp.com", port: 443]

config :chatbot,
  webhook_token: System.get_env("WEBHOOK_TOKEN"),
  fb_access_token: System.get_env("FB_ACCESS_TOKEN"),
  http_adapter: ChatbotWeb.Services.HttpAdapter
