defmodule ChatbotWeb.Utils.PayloadBuilder do
  @moduledoc """
  PayloadBuilder module contains the functions used to build different messages that can be sent to Facebook's Graph API and display to the user engaging with the bot.
  """

  @doc """
    Build default template that contains texts and buttons.

    Returns a list of maps which will be used to send messages to the user engaging with the bot.
  """
  @spec get_started_payload(String.t(), String.t()) :: list(map())
  def get_started_payload(psid, user) do
    [
      text_template(psid, "Welcome to CoinsBot, #{user}!"),
      text_template(psid, "I can look up information about crypto coins for you."),
      button_template(
        psid,
        "You can search for crypto by name or id",
        default_button_payload()
      )
    ]
  end

  @doc """
    Build default template that contains text and buttons.

    Returns a list of maps which will be used to send messages informing the user that no result found with their search term.
  """
  @spec not_found_payload(String.t(), String.t()) :: list(map())
  def not_found_payload(psid, coin_input) do
    [
      text_template(psid, "No results matching for #{coin_input}"),
      button_template(psid, "Would you like to search again?", default_button_payload())
    ]
  end

  @doc """
    Build default template that contains cards with buttons.

    Returns a map which will be used to send Facebook API and display up to 5 side-scrollable coins that can be used to view the price history in the bot inbox.
  """
  @spec top_coins_payload(String.t(), list(map())) :: map()
  def top_coins_payload(psid, coins) do
    cards_template(psid, build_coins_card_payload(coins))
  end

  @doc """
    Build default template that contains text with buttons element.

    Returns a map which contains text "Powered by CoinGecko" and give the user a choice to search again or restart the bot flow.
  """
  @spec after_lookup_payload(String.t()) :: map()
  def after_lookup_payload(psid) do
    button_template(
      psid,
      "This API is powered by CoinGecko.\n\nTo search again, press search by name or ID or the Restart button to start over.",
      default_button_payload()
    )
  end

  @doc """
    Base template for sending text elements in Facebook Messenger API.
  """
  @spec text_template(String.t(), String.t()) :: map()
  def text_template(psid, message) do
    %{recipient: %{id: psid}, message: %{text: message}}
  end

  @doc """
    Base template for sending text with buttons element in Facebook Messenger API.
  """
  @spec button_template(String.t(), String.t(), list(map())) :: map()
  def button_template(psid, text, buttons) do
    %{
      message: %{
        attachment: %{
          payload: %{
            buttons: buttons,
            template_type: "button",
            text: text
          },
          type: "template"
        }
      },
      recipient: %{id: psid}
    }
  end

  @doc """
    Base template for sending side-scrollable cards in Facebook Messenger API.
  """
  @spec cards_template(String.t(), list(map())) :: map()
  def cards_template(psid, elements) do
    %{
      message: %{
        attachment: %{
          payload: %{
            elements: elements,
            template_type: "generic"
          },
          type: "template"
        }
      },
      recipient: %{id: psid}
    }
  end

  # reusable buttons payload used in multiple templates throughout the bot flow
  @spec default_button_payload() :: list(map())
  defp default_button_payload do
    [
      %{payload: "name", title: "Search by name", type: "postback"},
      %{payload: "ID", title: "Search by ID", type: "postback"},
      %{payload: "Get Started", title: "Restart", type: "postback"}
    ]
  end

  # reusable card elements used in building top coin search results
  @spec build_coins_card_payload(list(map())) :: list(map())
  defp build_coins_card_payload(coins) do
    Enum.map(coins, fn coin ->
      %{
        buttons: [
          %{
            payload: %{coin_id: coin.id} |> Jason.encode!(),
            title: "Get Price History",
            type: "postback"
          }
        ],
        image_url: coin.thumb,
        subtitle: coin.symbol,
        title: coin.name
      }
    end)
  end
end
