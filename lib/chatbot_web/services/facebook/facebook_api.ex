defmodule ChatbotWeb.Services.Facebook.FacebookApi do
  @moduledoc """
  Module for calling Facebook API to fetch user data and send bot replies to the user.
  Uses the HttpAdapter module to process headers, request body and response body.
  """

  @base_url "https://graph.facebook.com"

  @doc """
  Calls the Facebook API to send bot replies depending on the crafted payload in PayloadBuilder module.
  """
  @spec send_message(map()) :: {:ok, map()} | {:error, map()}
  def send_message(body) do
    (@base_url <> "/v16.0/me/messages?access_token=#{access_token()}")
    |> http_adapter().post(body)
    |> handle_response()
  end

  @doc """
  Calls the Facebook API to fetch user's first name to be used in welcoming the user to the bot flow.
  """
  @spec get_user_information(String.t()) :: {:ok, map()} | {:error, map()}
  def get_user_information(psid) do
    (@base_url <> "/#{psid}?fields=first_name&access_token=#{access_token()}")
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
  defp access_token, do: Application.get_env(:chatbot, :fb_access_token)
end
