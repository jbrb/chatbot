defmodule ChatbotWeb.Services.Coingecko.CoingeckoApiTest do
  use ExUnit.Case

  import Mox

  alias ChatbotWeb.Services.Coingecko.CoingeckoApi

  describe "search_coin_by_name test" do
    test "returns {:ok, body} for valid requests" do
      coins = [
        %{
          coins: [
            %{
              id: "bitcoin",
              name: "Bitcoin",
              symbol: "BTC",
              thumb: "https://assets.coingecko.com/coins/images/1/thumb/bitcoin.png"
            }
          ]
        }
      ]

      HttpAdapterMock
      |> expect(:get, fn _url ->
        {:ok,
         %{
           body: %{coins: coins},
           status_code: 200
         }}
      end)

      assert {:ok, %{coins: fetched_coins}} = CoingeckoApi.search_coin_by_name("bitcoin")
      assert coins == fetched_coins
    end
  end

  describe "get_coin_by_id tests" do
    test "returns {:ok, body} for valid id" do
      mock_body = %{name: "Bitcoin"}

      HttpAdapterMock
      |> expect(:get, fn _url ->
        {:ok,
         %{
           body: mock_body,
           status_code: 200
         }}
      end)

      assert {:ok, result} = CoingeckoApi.get_coin_by_id("bitcoin")
      assert mock_body == result
    end

    test "returns 404 for not found results" do
      HttpAdapterMock
      |> expect(:get, fn _url ->
        {:ok,
         %{
           body: %{error: "not found"},
           status_code: 404
         }}
      end)

      assert {:error, %{error: "not found"}} = CoingeckoApi.get_coin_by_id("invalid")
    end

    test "test {:error, error} tuple return for handle_response" do
      mock_error = {:error, %{message: %{error: "Something went wrong."}}}

      HttpAdapterMock
      |> expect(:get, fn _url ->
        mock_error
      end)

      assert result = CoingeckoApi.get_coin_by_id("invalid")
      assert result == mock_error
    end
  end

  describe "get_coin_historical_data tests" do
    test "returns {:ok, body} for valid id with price history" do
      price_data = %{
        prices: [
          [1_674_691_200_000, 23180.422697874263],
          [1_674_777_600_000, 23024.74618081709]
        ]
      }

      HttpAdapterMock
      |> expect(:get, fn _url ->
        {:ok,
         %{
           body: price_data,
           status_code: 200
         }}
      end)

      assert {:ok, result} = CoingeckoApi.get_coin_historical_data("bitcoin")
      assert result == price_data
    end
  end
end
