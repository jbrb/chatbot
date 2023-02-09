defmodule Chatbot.ChatbotEts do
  @doc """
  Module for starting the ETS tables used for recording data

  coin_lookup table for storing user's search choice between coin name or coin ID
  user_info table acts as the DB for storing user's first time interaction with the bot
  """
  use GenServer

  def start_link(_) do
    GenServer.start_link(__MODULE__, [])
  end

  def init(state) do
    :ets.new(:coin_lookup, [:set, :public, :named_table])

    :ets.new(:user_info, [:set, :public, :named_table])

    {:ok, state}
  end
end
