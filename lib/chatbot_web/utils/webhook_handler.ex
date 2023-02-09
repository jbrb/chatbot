defmodule ChatbotWeb.Utils.WebhookHandler do
  @moduledoc """
  WebhookHandler module handles the webhook event received by the controller and process those events to return the corresponding bot response.
  """

  alias ChatbotWeb.Services.{Coingecko.CoingeckoApi, Facebook.FacebookApi}
  alias ChatbotWeb.Utils.PayloadBuilder

  @doc """
    Match for different webhook events received by the webhook controller.

    Builds the payload based on match and send the corresponding content to the user engaging with the bot.
  """

  # Match for the initial bot flow via the Get Started button
  # Fetches the user's first name and stores to ETS table for future usage
  # Build and sent the welcome text and buttons that can be used to let user choose between searching by coin name or coin ID
  @spec process_webhook_entry(map()) :: {:ok, map()} | {:error, map()} | list(map())
  def process_webhook_entry(%{
        "entry" => [
          %{
            "messaging" => [
              %{
                "postback" => %{"payload" => "Get Started", "title" => title},
                "sender" => %{"id" => psid}
              }
            ]
          }
        ],
        "object" => "page"
      })
      when title in ["Get Started", "Restart"] do
    :ets.delete(:coin_lookup, psid)

    user = get_user_data(psid)

    psid
    |> PayloadBuilder.get_started_payload(user)
    |> send_payload()
  end

  # Match for Postback when user chose to search via coin name or coin ID.
  # Server records the user's current search choice (name or ID) that can be used later when user entered his search keyword.
  # Builds and sends the text payload informing the user to input their search keyword that will be processed in the input match.
  def process_webhook_entry(%{
        "entry" => [
          %{
            "messaging" => [
              %{
                "postback" => %{
                  "payload" => search_by,
                  "title" => title
                },
                "sender" => %{"id" => psid}
              }
            ]
          }
        ],
        "object" => "page"
      })
      when title in ["Search by name", "Search by ID"] do
    :ets.insert(:coin_lookup, {psid, search_by})

    psid
    |> PayloadBuilder.text_template("Please enter the coin #{search_by}")
    |> send_payload()
  end

  # Match for user input lookup, process the input with the handle_coin_lookup/2 function to return side-scrollable cards with top search results.
  def process_webhook_entry(%{
        "entry" => [
          %{
            "messaging" => [
              %{
                "message" => %{"text" => text},
                "sender" => %{"id" => psid}
              }
            ]
          }
        ],
        "object" => "page"
      }) do
    handle_coin_lookup(psid, text)
  end

  # Match for Get Price History postback, process the input with the handle_coin_price_history/2 function to return the coin price history.
  def process_webhook_entry(%{
        "entry" => [
          %{
            "messaging" => [
              %{
                "postback" => %{
                  "payload" => coin_data,
                  "title" => "Get Price History"
                },
                "sender" => %{"id" => psid}
              }
            ]
          }
        ],
        "object" => "page"
      }) do
    %{coin_id: coin_id} = Jason.decode!(coin_data, keys: :atoms)

    handle_coin_price_history(psid, coin_id)
  end

  # Do nothing if the webhook is not in the defined flow
  def process_webhook_entry(_params), do: :ok

  # Handles the recorded user input to use the corresponding search API (via coin name or coin ID)
  @spec handle_coin_lookup(String.t(), String.t()) :: {:ok, map()} | {:error, map()}
  defp handle_coin_lookup(psid, coin_input) do
    case :ets.lookup(:coin_lookup, psid) do
      [] ->
        :ok

      [{_psid, "name"}] ->
        handle_coin_name_lookup(psid, coin_input)

      [{_psid, "ID"}] ->
        handle_coin_id_lookup(psid, coin_input)
    end
  end

  # Calls the CoinGecko's search API and builds the side-scrollable card elements as the bot's reply
  # returns not found template or error fetching result text element in case of no results and API fetching error
  @spec handle_coin_name_lookup(String.t(), String.t()) :: {:ok, map()} | {:error, map()}
  defp handle_coin_name_lookup(psid, coin_name) do
    response =
      case CoingeckoApi.search_coin_by_name(coin_name) do
        {:ok, %{coins: coins}} ->
          case coins do
            [] ->
              psid
              |> PayloadBuilder.not_found_payload(coin_name)
              |> send_payload()

            _ ->
              top_coins = Enum.slice(coins, 0..4)

              psid
              |> PayloadBuilder.top_coins_payload(top_coins)
              |> send_payload()
          end

        {:error, _error} ->
          psid
          |> PayloadBuilder.text_template("Error fetching results, please try again later.")
          |> send_payload()
      end

    :ets.delete(:coin_lookup, psid)
    response
  end

  # Calls the CoinGecko's get coin by ID API and builds a side-scrollable card elements as the bot's reply
  # returns not found template or error fetching result text element in case of no results and API fetching error
  @spec handle_coin_id_lookup(String.t(), String.t()) :: {:ok, map()} | {:error, map()}
  defp handle_coin_id_lookup(psid, coin_id) do
    response =
      case CoingeckoApi.get_coin_by_id(coin_id) do
        {:ok, body} ->
          coin = %{
            id: body.id,
            thumb: body.image.small,
            name: body.name,
            symbol: String.upcase(body.symbol)
          }

          psid
          |> PayloadBuilder.top_coins_payload([coin])
          |> send_payload()

        {:error, %{error: "coin not found"}} ->
          psid
          |> PayloadBuilder.not_found_payload(coin_id)
          |> send_payload()

        {:error, _error} ->
          psid
          |> PayloadBuilder.text_template("Error fetching results, please try again later.")
          |> send_payload()
      end

    :ets.delete(:coin_lookup, psid)
    response
  end

  # Calls the CoinGecko's market_chart API and builds text elements to display coin prices in the past 14 days
  @spec handle_coin_price_history(String.t(), String.t()) :: {:ok, map()} | {:error, map()}
  defp handle_coin_price_history(psid, coin_id) do
    case CoingeckoApi.get_coin_historical_data(coin_id) do
      {:ok, %{prices: prices}} ->
        prices
        |> Enum.take(14)
        |> Enum.each(fn [unix_time, price] ->
          date = unix_time
          |> DateTime.from_unix!(:millisecond)
          |> Timex.format!("{Mfull} {0D} {0YYYY}")

          psid
          |> PayloadBuilder.text_template("#{to_string(date)}\n\n#{price} USD")
          |> send_payload()
        end)

        :ets.delete(:coin_lookup, psid)

        psid
        |> PayloadBuilder.after_lookup_payload()
        |> send_payload()

      {:error, _error} ->
        psid
        |> PayloadBuilder.text_template("Error fetching results, please try again later.")
        |> send_payload()
    end
  end

  # Helper function save user data if not existing and read if data exists, used in text element welcoming the user to the bot flow
  @spec get_user_data(String.t()) :: String.t()
  defp get_user_data(psid) do
    case :ets.lookup(:user_info, psid) do
      [] ->
        case FacebookApi.get_user_information(psid) do
          {:ok, %{first_name: first_name}} ->
            :ets.insert(:user_info, {psid, first_name})
            first_name

          _ ->
            "CryptoBot User"
        end

      [{_psid, first_name}] ->
        first_name

      _ ->
        "CryptoBot User"
    end
  end

  # Helper function to send the built payload via PayloadBuilder module as a bot reply, sends sequentially if payload is a list
  @spec send_payload(list(map) | map()) :: {:ok, map()} | {:error, map()}
  defp send_payload(payload) when is_list(payload),
    do: Enum.map(payload, &FacebookApi.send_message/1)

  defp send_payload(payload) when is_map(payload), do: FacebookApi.send_message(payload)
end
