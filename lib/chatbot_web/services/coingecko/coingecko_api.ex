defmodule ChatbotWeb.Services.Coingecko.CoingeckoApi do
  @base_url "https://api.coingecko.com/api/v3"

  @doc """
  Calls the CoinGecko's /search API to fetch matching coins.
  Used by the Search by Name postback bot flow.
  """

  @spec search_coin_by_name(String.t()) :: {:ok, map()} | {:error, map()}
  def search_coin_by_name(coin_name) do
    (@base_url <> "/search?query=#{coin_name}")
    |> http_adapter().get()
    |> handle_response()
  end

  @doc """
  Calls the CoinGecko's coins/<coin_id>/ API to fetch coin via its ID.
  Used by the Search by ID postback bot flow.
  """
  @spec get_coin_by_id(String.t()) :: {:ok, map()} | {:error, map()}
  def get_coin_by_id(coin_id) do
    (@base_url <>
       "/coins/#{coin_id}?localization=false&tickers=false&market_data=false&community_data=false&developer_data=false&sparkline=false")
    |> http_adapter().get()
    |> handle_response()
  end

  @doc """
  Calls the CoinGecko's /market_chart API to fetch coin's price history.
  Used by the Get Price History postback bot flow.
  """
  @spec get_coin_historical_data(String.t()) :: {:ok, map()} | {:error, map()}
  def get_coin_historical_data(coin_id) do
    (@base_url <> "/coins/#{coin_id}/market_chart?vs_currency=usd&days=14&interval=daily")
    |> http_adapter().get()
    |> handle_response()
  end

  # Matches response to return successful and error API calls
  @spec handle_response(struct()) :: {:ok, map()} | {:error, map()}
  defp handle_response(response) do
    case response do
      {:ok, %{body: body, status_code: status_code}} when status_code in [200, 201] ->
        {:ok, body}

      {:ok, %{body: body, status_code: status_code}} when status_code in [400, 404, 422] ->
        {:error, body}

      {:error, error} ->
        {:error, error}
    end
  end

  defp http_adapter, do: Application.get_env(:chatbot, :http_adapter)
end
