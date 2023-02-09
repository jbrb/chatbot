defmodule ChatbotWeb.Services.HttpAdapter do
  @moduledoc """
  Reusable HTTP request and response processing module for external API services.
  """
  use HTTPoison.Base

  def process_request_body(""), do: ""
  def process_request_body(body), do: Jason.encode!(body)

  def process_response_body(body), do: Jason.decode!(body, keys: :atoms)

  def get(url), do: get(url, headers(), timeout: 30_000, recv_timeout: 30_000)

  def post(url, params), do: post(url, params, headers())

  defp headers, do: [{"Accept", " application/json"}, {"Content-Type", "application/json"}]
end
