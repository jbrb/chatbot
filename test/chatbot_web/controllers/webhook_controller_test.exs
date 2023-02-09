defmodule ChatbotWeb.WebhookControllerTest do
  use ChatbotWeb.ConnCase, async: true

  test "verify webhook token to register webhook URL in facebook app dashboard", %{conn: conn} do
    params = %{
      "hub.verify_token" => "test_token",
      "hub.challenge" => "test_challenge",
      "hub.mode" => "subscribe"
    }

    conn = get(conn, Routes.webhook_path(conn, :verify_token, params))

    assert conn.resp_body == params["hub.challenge"]
    assert conn.status == 200
  end

  test "verify webhook returns 403 if verify_token is invalid", %{conn: conn} do
    params = %{
      "hub.verify_token" => "invalid_token",
      "hub.challenge" => "test_challenge",
      "hub.mode" => "subscribe"
    }

    conn = get(conn, Routes.webhook_path(conn, :verify_token, params))

    assert conn.resp_body == "Forbidden"
    assert conn.status == 403
  end

  test "webhook function will always return 200 OK", %{conn: conn} do
    # params will match the catch all pattern (no action taken)
    conn = post(conn, Routes.webhook_path(conn, :webhook, %{}))

    assert conn.resp_body == "EVENT_RECEIVED"
    assert conn.status == 200
  end
end
