defmodule ChatbotWeb.Utils.WebhookHandlerTest do
  use ExUnit.Case

  import Mox

  alias ChatbotWeb.Utils.WebhookHandler

  describe "process_webhook_entry matches" do
    test "get started flow match should store user's name to ETS and return successful template send result" do
      get_started_payload = %{
        "entry" => [
          %{
            "messaging" => [
              %{
                "postback" => %{"payload" => "Get Started", "title" => "Get Started"},
                "sender" => %{"id" => "psid"}
              }
            ]
          }
        ],
        "object" => "page"
      }

      name = "John"
      psid = "psid"
      message_id = "message id"

      HttpAdapterMock
      |> expect(:get, fn _url ->
        {:ok,
         %{
           body: %{id: psid, first_name: name},
           status_code: 200
         }}
      end)
      |> expect(:post, 3, fn _url, _body ->
        {:ok,
         %{
           body: %{recipient_id: psid, message_id: message_id},
           status_code: 200
         }}
      end)

      result = WebhookHandler.process_webhook_entry(get_started_payload)

      assert [{^psid, ^name}] = :ets.lookup(:user_info, psid)
      assert Enum.all?(result, &(&1 == {:ok, %{recipient_id: psid, message_id: message_id}}))
    end

    test "select search by coin name or id flow should record user search choice" do
      search_by = "name"
      psid = "psid"
      message_id = "message id"

      payload = %{
        "entry" => [
          %{
            "messaging" => [
              %{
                "postback" => %{
                  "payload" => search_by,
                  "title" => "Search by ID"
                },
                "sender" => %{"id" => psid}
              }
            ]
          }
        ],
        "object" => "page"
      }

      HttpAdapterMock
      |> expect(:post, 1, fn _url, _body ->
        {:ok,
         %{
           body: %{recipient_id: psid, message_id: message_id},
           status_code: 200
         }}
      end)

      result = WebhookHandler.process_webhook_entry(payload)

      assert [{^psid, ^search_by}] = :ets.lookup(:coin_lookup, "psid")
      assert result == {:ok, %{recipient_id: psid, message_id: message_id}}
    end

    test "search by name should return {:ok, body} and search by is deleted in ETS after" do
      search_keyword = "bitcoin"
      search_by = "name"
      psid = "psid"
      message_id = "message id"

      payload = %{
        "entry" => [
          %{
            "messaging" => [
              %{
                "message" => %{"text" => search_keyword},
                "sender" => %{"id" => psid}
              }
            ]
          }
        ],
        "object" => "page"
      }

      :ets.insert(:coin_lookup, {psid, search_by})

      assert [{^psid, ^search_by}] = :ets.lookup(:coin_lookup, "psid")

      HttpAdapterMock
      |> expect(:get, fn _url ->
        {:ok,
         %{
           body: %{
             coins: [
               %{
                 id: "bitcoin",
                 name: "Bitcoin",
                 symbol: "BTC",
                 thumb: "https://assets.coingecko.com/coins/images/1/thumb/bitcoin.png"
               }
             ]
           },
           status_code: 200
         }}
      end)
      |> expect(:post, 1, fn _url, _body ->
        {:ok,
         %{
           body: %{recipient_id: psid, message_id: message_id},
           status_code: 200
         }}
      end)

      result = WebhookHandler.process_webhook_entry(payload)
      assert result == {:ok, %{recipient_id: psid, message_id: message_id}}

      # ensure lookup by name or id is deleted since the lookup is finished
      assert [] = :ets.lookup(:coin_lookup, psid)
    end

    test "parse user input sent via webhook to get the coin by ID and search by is deleted in ETS after" do
      search_keyword = "bitcoin"
      search_by = "ID"
      psid = "psid"
      message_id = "message id"

      payload = %{
        "entry" => [
          %{
            "messaging" => [
              %{
                "message" => %{"text" => search_keyword},
                "sender" => %{"id" => psid}
              }
            ]
          }
        ],
        "object" => "page"
      }

      :ets.insert(:coin_lookup, {psid, search_by})

      assert [{^psid, ^search_by}] = :ets.lookup(:coin_lookup, "psid")

      HttpAdapterMock
      |> expect(:get, fn _url ->
        {:ok,
         %{
           body: %{id: "bitcoin", image: %{small: "image"}, name: "BitCoin", symbol: "BTC"},
           status_code: 200
         }}
      end)
      |> expect(:post, 1, fn _url, _body ->
        {:ok,
         %{
           body: %{recipient_id: psid, message_id: message_id},
           status_code: 200
         }}
      end)

      result = WebhookHandler.process_webhook_entry(payload)
      assert result == {:ok, %{recipient_id: psid, message_id: message_id}}

      # ensure lookup by name or id is deleted since the lookup is finished
      assert [] = :ets.lookup(:coin_lookup, psid)
    end

    test "match for get price history payload" do
      psid = "psid"
      message_id = "message id"

      payload = %{
        "entry" => [
          %{
            "messaging" => [
              %{
                "postback" => %{
                  "payload" => "{\"coin_id\":\"bitcoin\"}",
                  "title" => "Get Price History"
                },
                "sender" => %{"id" => psid}
              }
            ]
          }
        ],
        "object" => "page"
      }

      HttpAdapterMock
      |> expect(:get, fn _url ->
        {:ok,
         %{
           body: %{
             prices: [
               [1_674_691_200_000, 23180.422697874263],
               [1_674_777_600_000, 23024.74618081709]
             ]
           },
           status_code: 200
         }}
      end)
      |> expect(:post, 3, fn _url, _body ->
        {:ok,
         %{
           body: %{recipient_id: psid, message_id: message_id},
           status_code: 200
         }}
      end)

      result = WebhookHandler.process_webhook_entry(payload)

      assert result == {:ok, %{recipient_id: psid, message_id: message_id}}
    end

    test "returns :ok when event falls to default match (do nothing)" do
      result = WebhookHandler.process_webhook_entry(%{})

      assert result == :ok
    end
  end
end
