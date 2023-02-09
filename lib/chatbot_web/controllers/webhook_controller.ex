defmodule ChatbotWeb.WebhookController do
  use ChatbotWeb, :controller

  alias ChatbotWeb.Utils.WebhookHandler

  def verify_token(conn, %{"hub.mode" => "subscribe"} = params) do
    if params["hub.verify_token"] == webhook_token() do
      send_resp(conn, 200, params["hub.challenge"])
    else
      send_resp(conn, 403, "Forbidden")
    end
  end

  def webhook(conn, params) do
    Task.start(fn -> WebhookHandler.process_webhook_entry(params) end)

    send_resp(conn, 200, "EVENT_RECEIVED")
  end

  defp webhook_token, do: Application.get_env(:chatbot, :webhook_token)
end
