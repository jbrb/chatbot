defmodule ChatbotWeb.Router do
  use ChatbotWeb, :router

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/api", ChatbotWeb do
    get "/webhook", WebhookController, :verify_token
    post "/webhook", WebhookController, :webhook

    pipe_through :api
  end
end
